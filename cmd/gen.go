package cmd

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"log"
	"os"

	"github.com/DNSControl/dnscontrol/v5/pkg/dnsrr"
	"github.com/DNSControl/dnscontrol/v5/pkg/printer"
	"github.com/DNSControl/dnscontrol/v5/pkg/zonerecs"
	"github.com/hm-edu/dnscontrol-extended/helper"

	"net/netip"
	"regexp"
	"strings"

	"codeberg.org/miekg/dns"
	"github.com/DNSControl/dnscontrol/v5/models"
	"github.com/DNSControl/dnscontrol/v5/pkg/providers"
	"github.com/DNSControl/dnscontrol/v5/pkg/transform"
	_ "github.com/DNSControl/dnscontrol/v5/providers/bind"
	"github.com/spf13/cobra"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

func genLogger() *zap.Logger {

	config := zap.NewProductionEncoderConfig()
	config.EncodeTime = zapcore.ISO8601TimeEncoder
	config.EncodeLevel = zapcore.CapitalColorLevelEncoder
	consoleEncoder := zapcore.NewConsoleEncoder(config)
	defaultLogLevel := zapcore.DebugLevel

	core := zapcore.NewTee(
		zapcore.NewCore(consoleEncoder, zapcore.AddSync(os.Stdout), defaultLogLevel),
	)
	logger := zap.New(core, zap.AddStacktrace(zapcore.FatalLevel))
	return logger
}

var genCmd = &cobra.Command{
	Use:   "gen",
	Short: "Queries the forward zones and generates a new reverse zone",
	Run: func(cmd *cobra.Command, args []string) {
		logger := genLogger()
		patternTxt, _ := regexp.Compile("hm-reverse-lookup-ip=(.*)")
		patternName, _ := regexp.Compile("_hmip_(.*)")
		writer := &helper.Writer{Log: logger}
		printer.DefaultPrinter = &printer.ConsolePrinter{
			Reader:  bufio.NewReader(os.Stdin),
			Writer:  writer,
			Verbose: false,
		}
		defer writer.Close()
		domains, _ := cmd.Flags().GetStringSlice("domains")
		zones, _ := cmd.Flags().GetStringSlice("zones")
		ns, _ := cmd.Flags().GetStringSlice("nameservers")
		mbox, _ := cmd.Flags().GetString("mbox")

		dir, _ := cmd.Flags().GetString("path")

		var cfg = map[string]string{}

		cfg["directory"] = dir
		cfg["filenameformat"] = "zone.%U"
		provider, err := providers.CreateDNSProvider("BIND", cfg, nil)
		if err != nil {
			logger.Sugar().Fatalf("error creating bind provider %v", err)
		}

		var records []dns.RR
		for _, domain := range domains {
			logger.Sugar().Infof("getting records in domain %s", domain)
			entries, err := getRecords(domain)
			if err != nil {
				logger.Sugar().Fatalf("error querying domain %s %v", domain, err)
			}
			records = append(records, entries...)
		}

		for _, zone := range zones {
			prefix, err := netip.ParsePrefix(zone)
			if err != nil {
				logger.Sugar().Fatalf("error generating reverse zone for %s %v", zone, err)
			}
			name, err := transform.ReverseDomainName(zone)
			if err != nil {
				logger.Sugar().Fatalf("error generating reverse zone for %s %v", zone, err)
			}
			config, err := models.NewDomainConfig(name)
			if err != nil {
				logger.Sugar().Fatalf("error generating reverse zone for %s %v", zone, err)
			}
			entries := make(map[string]string)
			ptrRecords := models.Records{}

			soa, err := dns.New(fmt.Sprintf("%s. IN SOA %s %s 0 0 0 0 0", name, ns[0], mbox))
			if err != nil {
				logger.Sugar().Fatalf("error generating soa for %s %v", zone, err)
			}
			rec, err := dnsrr.RRv2toRC(config, soa)
			if err != nil {
				logger.Sugar().Fatalf("error generating reverse zone for %s %v", zone, err)
			}
			ptrRecords = append(ptrRecords, rec)

			for _, server := range ns {

				dnsRR, err := dns.New(fmt.Sprintf("%s. IN NS %s", name, server))
				if err != nil {
					logger.Sugar().Fatalf("error generating ns record for %s %v", zone, err)
				}

				rec, err := dnsrr.RRv2toRC(config, dnsRR)
				if err != nil {
					logger.Sugar().Fatalf("error generating reverse zone for %s %v", zone, err)
				}
				ptrRecords = append(ptrRecords, rec)
			}

			for _, record := range records {
				if a, ok := record.(*dns.A); ok {
					if !prefix.Contains(a.Addr) {
						continue
					}
					revName, err := transform.ReverseDomainName(a.Addr.String())
					if err != nil {
						logger.Sugar().Fatalf("error adding ptr %v", err)
					}

					if record, found := entries[revName]; found {
						logger.Sugar().Warnf("replacing existing record %s with %s", record, a.Hdr.Name)
					}
					entries[revName] = a.Hdr.Name
				}
			}
			for _, record := range records {
				if txt, ok := record.(*dns.TXT); ok {
					if okRevIp := patternTxt.MatchString(txt.String()); okRevIp {
						if okHmIp := patternName.MatchString(txt.Hdr.Name); okHmIp {
							matches := patternTxt.FindStringSubmatch(txt.String())
							ip := matches[1]
							ip = strings.TrimSpace(strings.Trim(ip, "\""))
							addr, err := netip.ParseAddr(ip)
							if err != nil || !prefix.Contains(addr) {
								continue
							}
							revName, err := transform.ReverseDomainName(ip)
							if err != nil {
								log.Fatalf("error adding ptr %v", err)
							}
							name := patternName.FindStringSubmatch(txt.Hdr.Name)[1]
							if record, found := entries[revName]; found {
								if record != name {
									logger.Sugar().Infof("replacing existing record for %s using txt record: %s %s", ip, record, name)
								}
							} else {
								logger.Sugar().Warnf("adding reverse entry without forward entry for %s -> %s", ip, name)
							}
							entries[revName] = name
						}
					}
				}
			}

			for key, value := range entries {
				rr, err := dns.New(fmt.Sprintf("%s. IN PTR %s", key, strings.ToLower(value)))
				if err != nil {
					log.Fatalf("error adding ptr %v", err)
				}
				rec, err := dnsrr.RRv2toRC(config, rr)
				if err != nil {
					log.Fatalf("error adding ptr %v", err)
				}
				ptrRecords = append(ptrRecords, rec)
			}

			var nameservers []*models.Nameserver
			for _, server := range ns {
				nameservers = append(nameservers, &models.Nameserver{Name: server})
			}
			config.Records = ptrRecords
			config.Nameservers = nameservers
			_, corrections, _, err := zonerecs.CorrectZoneRecords(provider, config)
			if err != nil {
				logger.Sugar().Fatalf("error computing domain corrections %v", err)
			}
			if len(corrections) == 0 {
				logger.Sugar().Infof("no changes required for zone %s", name)
			} else {
				for _, correction := range corrections {
					msgs := strings.Split(correction.Msg, "\n")
					logger.Sugar().Infof("Applying changes to zone %s", zone)
					for _, msg := range msgs {
						logger.Sugar().Infof("%s", msg)
					}
					err := correction.F()
					if err != nil {
						logger.Sugar().Fatalf("error applying corrections %v", err)
					}
				}
			}
		}

	}}

func getRecords(zone string) ([]dns.RR, error) {
	const server = "127.0.0.1:53"

	client := dns.NewClient()
	request := dns.NewMsg(zone+".", dns.TypeAXFR)
	envelope, err := client.TransferIn(context.Background(), request, "tcp", server)
	if err != nil {
		return nil, err
	}

	var rawRecords []dns.RR
	for msg := range envelope {
		if msg.Error != nil {
			// Fragile but more "user-friendly" error-handling
			reason := msg.Error.Error()
			if errors.Is(msg.Error, dns.ErrRcode) && strings.HasSuffix(reason, dns.RcodeToString[dns.RcodeNotAuth]) {
				reason = "NOT AUTH (9)"
			}
			return nil, fmt.Errorf("[Error] AXFRDDNS: nameserver refused to transfer the zone: %s", reason)
		}
		rawRecords = append(rawRecords, msg.Answer...)
	}
	return rawRecords, nil
}

func init() {
	rootCmd.AddCommand(genCmd)

	genCmd.Flags().StringSliceP("domains", "d", []string{}, "the domains to query for computation of reverse zone")
	genCmd.Flags().StringSliceP("zones", "z", []string{}, "the ip ranges reverse zones shall be generated for")
	genCmd.Flags().StringSliceP("nameservers", "n", []string{}, "the nameservers to use in the generated zone file")
	genCmd.Flags().String("mbox", "", "the desired soa mbox")
	genCmd.Flags().String("path", "/etc/bind/zones/reverse", "the path for storing the reverse zones")

	genCmd.MarkFlagRequired("domains")
	genCmd.MarkFlagRequired("zones")
	genCmd.MarkFlagRequired("nameservers")
	genCmd.MarkFlagRequired("mbox")

}
