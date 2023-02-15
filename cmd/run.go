/*
Copyright © 2023 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"fmt"
	"net"
	"os"
	"strings"

	"github.com/StackExchange/dnscontrol/v3/pkg/transform"
	"github.com/miekg/dns"
	"github.com/spf13/cobra"
	"github.com/xanzy/go-gitlab"
)

// runCmd represents the run command
var runCmd = &cobra.Command{
	Use:   "run",
	Short: "Parse the reverse zones and determine the free records",
	Run: func(cmd *cobra.Command, args []string) {
		zone, _ := cmd.Flags().GetString("zone")
		pat, _ := cmd.Flags().GetString("pat")
		api, _ := cmd.Flags().GetString("api")
		projectID, _ := cmd.Flags().GetString("project")
		name, err := transform.ReverseDomainName(zone)
		if err != nil {
			panic(err)
		}
		fmt.Printf("Parsing reverse zone %s\n", name)
		hosts, err := Hosts(zone)
		if err != nil {
			panic(err)
		}
		file := "zones/" + name + ".zone"
		content, err := os.ReadFile(file)
		if err != nil {
			panic(err)
		}
		zp := dns.NewZoneParser(strings.NewReader(string(content)), name, file)
		records := []dns.RR{}
		for rr, ok := zp.Next(); ok; rr, ok = zp.Next() {
			records = append(records, rr)
		}

		client, err := gitlab.NewClient(pat, gitlab.WithBaseURL(api))
		if err != nil {
			panic(err)
		}
		project, _, err := client.Projects.GetProject(projectID, nil)
		if err != nil {
			panic(err)
		}
		issues, _, err := client.Issues.ListProjectIssues(project.ID, &gitlab.ListProjectIssuesOptions{
			Search: gitlab.String("Free IPs in " + zone),
		})
		if err != nil {
			panic(err)
		}
		var issue *gitlab.Issue
		if len(issues) == 0 {
			issue, _, err = client.Issues.CreateIssue(project.ID, &gitlab.CreateIssueOptions{
				Title:       gitlab.String("Free IPs in " + zone),
				Description: gitlab.String(""),
			})
			if err != nil {
				panic(err)
			}
		} else {
			issue = issues[0]
		}
		var description string
		for _, host := range hosts {
			found := false
			for _, record := range records {
				ptr, ok := record.(*dns.PTR)
				if ok {
					n, err := transform.ReverseDomainName(host)
					if err != nil {
						panic(err)
					}
					if ptr.Hdr.Name == fmt.Sprintf("%s.", n) {
						found = true
						description += fmt.Sprintf("- [x]  %s: %s\n", host, ptr.Ptr)
						break
					}
				}
			}
			if !found {
				description += fmt.Sprintf("- [ ]  %s: \n", host)
			}
		}

		_, _, err = client.Issues.UpdateIssue(project.ID, issue.IID, &gitlab.UpdateIssueOptions{
			Description: gitlab.String(description),
		})
		if err != nil {
			panic(err)
		}
	},
}

func Hosts(cidr string) ([]string, error) {
	ip, ipnet, err := net.ParseCIDR(cidr)
	if err != nil {
		return nil, err
	}

	var ips []string
	for ip := ip.Mask(ipnet.Mask); ipnet.Contains(ip); inc(ip) {
		ips = append(ips, ip.String())
	}
	// remove network address and broadcast address
	return ips[1 : len(ips)-1], nil
}

func inc(ip net.IP) {
	for j := len(ip) - 1; j >= 0; j-- {
		ip[j]++
		if ip[j] > 0 {
			break
		}
	}
}
func init() {
	rootCmd.AddCommand(runCmd)

	runCmd.Flags().StringP("zone", "z", "", "The ip-range to parse")
	runCmd.Flags().StringP("pat", "p", "", "The personal access token for the gitlab api")
	runCmd.Flags().StringP("api", "a", "", "The gitlab api url")
	runCmd.Flags().StringP("project", "i", "", "The gitlab project id")
}
