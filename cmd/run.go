package cmd

import (
	"encoding/json"
	"fmt"
	"log"
	"net"
	"os"
	"path"
	"strconv"
	"strings"
	"time"

	"go.uber.org/zap"
	"golang.org/x/time/rate"

	"github.com/StackExchange/dnscontrol/v4/pkg/transform"
	"github.com/hm-edu/dnscontrol-extended/helper"
	"github.com/miekg/dns"
	"github.com/spf13/cobra"
	"github.com/xanzy/go-gitlab"
)

func init() {
	rootCmd.AddCommand(runCmd)

	runCmd.Flags().StringP("zone", "z", "", "The ip-range to parse")
	runCmd.Flags().StringP("subnets", "s", "", "The (optional) subnet size (the net and broadcast address of the subnets can be enabled using the pseudo flag)")
	runCmd.Flags().StringP("pat", "p", "", "The personal access token for the gitlab api")
	runCmd.Flags().StringP("api", "a", "", "The gitlab api url")
	runCmd.Flags().StringP("project", "i", "", "The gitlab project id")
	runCmd.Flags().BoolP("empty", "e", false, "Include empty subnets")
	runCmd.Flags().String("inner", "", "The inner subnet size")
	runCmd.Flags().StringP("dir", "d", "zones", "the location of reverse zones")
	runCmd.Flags().StringSliceP("formats", "f", []string{"zone.%s", "%s.zone", "%s.db", "db.%s"}, "the filename patterns to search the reverse zone")
	runCmd.Flags().Bool("pseudo", true, "Include the network and broadcast addresses of all subnets. Useful if firewall rules handle the complete parent subnet.")
	runCmd.Flags().String("labels", "", "The tags to be added to the subnets")
	runCmd.MarkFlagRequired("zone")
	runCmd.MarkFlagRequired("pat")
	runCmd.MarkFlagRequired("api")
	runCmd.MarkFlagRequired("project")
}

// runCmd represents the run command
var runCmd = &cobra.Command{
	Use:   "run",
	Short: "Parse the reverse zones and determine the free records",
	Run: func(cmd *cobra.Command, args []string) {
		logger := genLogger()
		zone, _ := cmd.Flags().GetString("zone")
		pat, _ := cmd.Flags().GetString("pat")
		api, _ := cmd.Flags().GetString("api")
		pseudo, _ := cmd.Flags().GetBool("pseudo")
		projectID, _ := cmd.Flags().GetString("project")
		empty, _ := cmd.Flags().GetBool("empty")
		subnets, _ := cmd.Flags().GetString("subnets")
		inner, _ := cmd.Flags().GetString("inner")
		fileNameFormats, _ := cmd.Flags().GetStringSlice("formats")
		dir, _ := cmd.Flags().GetString("dir")
		tagsPath, _ := cmd.Flags().GetString("labels")
		var labels []helper.Label

		if tagsPath != "" {
			data, err := os.ReadFile(tagsPath)
			if err != nil {
				log.Fatal(err)
			}

			err = json.Unmarshal(data, &labels)
			if err != nil {
				log.Fatal(err)
			}
		}

		var nets []*net.IPNet

		// Check if we shal generate subnetted issues
		if subnets != "" {
			s, err := strconv.Atoi(subnets)
			if err != nil {
				log.Fatal(err)
			}
			// Calculate required subnets
			nets, err = helper.Subnets(zone, s)
			if err != nil {
				log.Fatal(err)
			}
		} else {
			_, n, err := net.ParseCIDR(zone)
			if err != nil {
				log.Fatal(err)
			}
			nets = []*net.IPNet{n}
		}

		name, err := transform.ReverseDomainName(zone)
		if err != nil {
			panic(err)
		}
		logger.Sugar().Infof("Parsing reverse zone %s\n", name)
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

		recordMap := make(map[string]string)

		for _, record := range records {
			ptr, ok := record.(*dns.PTR)
			if ok {
				recordMap[ptr.Hdr.Name] = ptr.Ptr
			}
		}

		c := make(chan helper.SubnetResponse)
		defer close(c)

		for _, net := range nets {
			go computeSubnetContent(net, logger, recordMap, pseudo, c)
		}

		var subnetItems []helper.SubnetResponse
		for range nets {
			subnetItems = append(subnetItems, <-c)
		}
		client, err := gitlab.NewClient(pat, gitlab.WithBaseURL(api), gitlab.WithCustomLimiter(rate.NewLimiter(rate.Every(time.Minute/300), 1)))
		if err != nil {
			panic(err)
		}
		project, _, err := client.Projects.GetProject(projectID, nil)
		if err != nil {
			panic(err)
		}
		for _, item := range labels {
			// Create tags if not existing
			_, _, err := client.Labels.CreateLabel(projectID, &gitlab.CreateLabelOptions{
				Name:  gitlab.String(item.Label),
				Color: gitlab.String(fmt.Sprintf("#%06x", item.Color))})
			if err != nil {
				logger.Sugar().Warn(err)
			}
		}
		items, _, err := client.Issues.ListProjectIssues(project.ID, &gitlab.ListProjectIssuesOptions{})
		if err != nil {
			panic(err)
		}
		helper.GenerateGitlabIssue(subnetItems, pat, api, projectID, zone, logger, empty, &inner, project, items, client, labels)
	},
}

func computeSubnetContent(net *net.IPNet, logger *zap.Logger, recordMap map[string]string, pseudo bool, c chan helper.SubnetResponse) {
	hosts, err := helper.Hosts(net, pseudo)
	var section string
	logger.Sugar().Infof("Calculate IP usage for %s", net.String())
	if err != nil {
		panic(err)
	}
	foundHosts := 0
	for _, host := range hosts {
		n, err := transform.ReverseDomainName(host)
		if err != nil {
			panic(err)
		}
		n = fmt.Sprintf("%s.", n)
		if rr, ok := recordMap[n]; ok {
			foundHosts++
			section += fmt.Sprintf("- [x]  %s: %s\n", host, rr)
		} else {
			section += fmt.Sprintf("- [ ]  %s: \n", host)
		}
	}
	logger.Sugar().Infof("Calculated IP usage for %s", net.String())
	if foundHosts == 0 {
		section = fmt.Sprintf("No IPs used within %s \n", net.String())
		c <- helper.SubnetResponse{Net: net.String(), Section: section, Empty: true}
	} else {
		c <- helper.SubnetResponse{Net: net.String(), Section: section, Empty: false}
	}
}
