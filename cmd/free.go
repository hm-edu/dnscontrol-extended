package cmd

import (
	"fmt"
	"log"
	"net"
	"os"
	"path"
	"strings"

	"github.com/StackExchange/dnscontrol/v3/pkg/transform"
	"github.com/hm-edu/dnscontrol-extended/helper"
	"github.com/miekg/dns"
	"github.com/spf13/cobra"
)

// runCmd represents the run command
var freeCmd = &cobra.Command{
	Use:   "free",
	Short: "Parse the reverse zones and determine the free records",
	Run: func(cmd *cobra.Command, args []string) {
		zone, _ := cmd.Flags().GetString("zone")
		subnet, _ := cmd.Flags().GetString("subnet")
		dir, _ := cmd.Flags().GetString("dir")
		pseudo, _ := cmd.Flags().GetBool("pseudo")
		fileNameFormats, _ := cmd.Flags().GetStringSlice("formats")
		name, err := transform.ReverseDomainName(zone)
		if err != nil {
			panic(err)
		}
		fmt.Printf("Parsing reverse zone %s\n", name)

		var hosts []string
		var network *net.IPNet
		if subnet == "" {
			_, network, err = net.ParseCIDR(zone)
		} else {
			_, network, err = net.ParseCIDR(subnet)
		}
		if err != nil {
			log.Fatal(err)
		}
		hosts, err = helper.Hosts(network, pseudo)

		if err != nil {
			panic(err)
		}
		var zp *dns.ZoneParser
		var records []dns.RR
		for _, format := range fileNameFormats {

			file := fmt.Sprintf(format, name)

			content, err := os.ReadFile(path.Join(dir, file))
			if err != nil {
				continue
			}
			zp = dns.NewZoneParser(strings.NewReader(string(content)), name, file)
			for rr, ok := zp.Next(); ok; rr, ok = zp.Next() {
				records = append(records, rr)
			}
			break
		}
		if zp == nil {
			log.Fatal("reading zone not possible!")
		}
		var description string
		for _, host := range hosts {
			found := false
			n, err := transform.ReverseDomainName(host)
			if err != nil {
				panic(err)
			}
			n = fmt.Sprintf("%s.", n)
			for _, record := range records {
				ptr, ok := record.(*dns.PTR)
				if ok {
					if ptr.Hdr.Name == n {
						found = true
						break
					}
				}
			}
			if !found {
				description += fmt.Sprintf(" - %s\n", host)
			}
		}
		fmt.Printf("Free IPs: \n%s", description)
	},
}

func init() {
	rootCmd.AddCommand(freeCmd)

	freeCmd.Flags().StringP("zone", "z", "", "The ip-range to parse")
	freeCmd.Flags().StringP("subnet", "s", "", "The subnet to query")
	freeCmd.Flags().StringP("dir", "d", "/etc/bind/zones/reverse", "the location of reverse zones")
	freeCmd.Flags().StringSliceP("formats", "f", []string{"zone.%s", "%s.zone", "%s.db", "db.%s"}, "the filename patterns to search the reverse zone")
	freeCmd.Flags().Bool("pseudo", false, "Include the network and broadcast addresses of all subnets. Useful if firewall rules handle the complete parent subnet.")

	freeCmd.MarkFlagRequired("zone")

}
