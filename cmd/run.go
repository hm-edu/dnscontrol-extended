package cmd

import (
	"fmt"
	"log"
	"net"
	"net/netip"
	"os"
	"sort"
	"strconv"
	"strings"

	"go.uber.org/zap"

	"github.com/StackExchange/dnscontrol/v3/pkg/transform"
	"github.com/hm-edu/dnscontrol-extended/helper"
	"github.com/miekg/dns"
	"github.com/spf13/cobra"
	"github.com/xanzy/go-gitlab"
)

type subnetResponse struct {
	net     string
	section string
	empty   bool
}

type ByNet []subnetResponse

func (a ByNet) Len() int { return len(a) }
func (a ByNet) Less(i, j int) bool {
	x, _, _ := net.ParseCIDR(a[i].net)
	y, _, _ := net.ParseCIDR(a[j].net)
	n := netip.MustParseAddr(x.String())
	m := netip.MustParseAddr(y.String())
	return n.Less(m)
}
func (a ByNet) Swap(i, j int) {
	a[i], a[j] = a[j], a[i]
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

		var nets []*net.IPNet

		if subnets != "" {
			s, err := strconv.Atoi(subnets)
			if err != nil {
				log.Fatal(err)
			}
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

		file := "zones/" + name + ".zone"
		content, err := os.ReadFile(file)
		if err != nil {
			panic(err)
		}
		zp := dns.NewZoneParser(strings.NewReader(string(content)), name, file)
		var records []dns.RR
		for rr, ok := zp.Next(); ok; rr, ok = zp.Next() {
			records = append(records, rr)
		}

		recordMap := make(map[string]string)

		for _, record := range records {
			ptr, ok := record.(*dns.PTR)
			if ok {
				recordMap[ptr.Hdr.Name] = ptr.Ptr
			}
		}

		c := make(chan subnetResponse)
		for _, net := range nets {
			go handleSubnet(net, logger, recordMap, pseudo, c)
		}

		var items []subnetResponse

		for range nets {
			items = append(items, <-c)
		}

		close(c)

		sort.Sort(ByNet(items))

		generateGitlabIssue(nets, items, pat, api, projectID, zone, logger, empty)
	},
}

func handleSubnet(net *net.IPNet, logger *zap.Logger, recordMap map[string]string, pseudo bool, c chan subnetResponse) {
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
		c <- subnetResponse{net: net.String(), section: section, empty: true}
	} else {
		c <- subnetResponse{net: net.String(), section: section, empty: false}
	}
}

func generateGitlabIssue(nets []*net.IPNet, items []subnetResponse, pat, api, projectID, zone string, logger *zap.Logger, empty bool) {

	var description string
	var i int
	if len(nets) == 1 {
		description = items[0].section
		if len([]byte(description)) > (1024 * 512) {
			logger.Sugar().Fatalf("Issue description will be to large. Consider splitting information into subnets.")
		}
	} else {
		for _, item := range items {
			if len([]byte(description)) > (1024 * 512) {
				description += "\n\nPlease check comments."
				break
			}
			description = generateDescription(item, description, empty)
			i++
		}
	}

	client, err := gitlab.NewClient(pat, gitlab.WithBaseURL(api))
	if err != nil {
		panic(err)
	}
	project, _, err := client.Projects.GetProject(projectID, nil)
	if err != nil {
		panic(err)
	}
	var issues []*gitlab.Issue
	for _, format := range []string{"IP usage in %s", "Free IPs in %s"} {
		items, _, err := client.Issues.ListProjectIssues(project.ID, &gitlab.ListProjectIssuesOptions{
			Search: gitlab.String(fmt.Sprintf(format, zone)),
		})
		if err != nil {
			panic(err)
		}
		issues = append(issues, items...)
	}
	var issue *gitlab.Issue
	if len(issues) == 0 {
		logger.Sugar().Infof("Found no existing issue. Creating new.")
		issue, _, err = client.Issues.CreateIssue(project.ID, &gitlab.CreateIssueOptions{
			Title:       gitlab.String("IP usage in " + zone),
			Description: gitlab.String(""),
		})
		if err != nil {
			panic(err)
		}
	} else {
		issue = issues[0]
	}

	logger.Sugar().Infof("Updating issue description.")
	_, _, err = client.Issues.UpdateIssue(project.ID, issue.IID, &gitlab.UpdateIssueOptions{
		Title:       gitlab.String("IP usage in " + zone),
		Description: gitlab.String(description),
	})
	if err != nil {
		panic(err)
	}
	logger.Sugar().Infof("Purging old comments")
	notes, _, err := client.Notes.ListIssueNotes(project.ID, issue.IID, &gitlab.ListIssueNotesOptions{})
	if err != nil {
		panic(err)
	}
	for _, note := range notes {
		if !note.System {
			logger.Sugar().Infof("Deletig comment %s", note.Body)
			_, err = client.Notes.DeleteIssueNote(project.ID, issue.IID, note.ID)
			if err != nil {
				logger.Sugar().Errorf("Deleting comment %s failed. This commonly happens due to missing permissions. Maybe the comment was created by somebody else? (Error: %v)", note.Body, err)
			}
		}
	}
	if len(nets) != 1 && len(nets) != i {
		logger.Sugar().Infof("Description handles %d subnets. %d remaining -> Placing into comments", i, len(nets)-i)
		for {
			description = ""
			inserted := false
			for _, item := range items[i:] {
				if len([]byte(description)) > (1024 * 512) {
					description += "\n\nPlease check comments"
					_, _, err := client.Notes.CreateIssueNote(project.ID, issue.IID, &gitlab.CreateIssueNoteOptions{Body: gitlab.String(description)})
					if err != nil {
						panic(err)
					}
					inserted = true
					break
				}
				description = generateDescription(item, description, empty)
				i++
			}
			if i == len(nets) {
				if !inserted {
					_, _, err := client.Notes.CreateIssueNote(project.ID, issue.IID, &gitlab.CreateIssueNoteOptions{Body: gitlab.String(description)})
					if err != nil {
						panic(err)
					}
				}
				break
			}
		}
	}
}

func generateDescription(net subnetResponse, description string, empty bool) string {
	if !net.empty {
		description += fmt.Sprintf("## %s \n<details><summary>IPs:</summary>\n\n%s\n</details>\n\n", net.net, net.section)
	} else if empty {
		description += fmt.Sprintf("%s\n\n%s\n\n\n", net.net, net.section)
	}
	return description
}

func init() {
	rootCmd.AddCommand(runCmd)

	runCmd.Flags().StringP("zone", "z", "", "The ip-range to parse")
	runCmd.Flags().StringP("subnets", "s", "", "The (optional) subnet size (the net and broadcast address of the subnets can be enabled using the pseudo flag)")
	runCmd.Flags().StringP("pat", "p", "", "The personal access token for the gitlab api")
	runCmd.Flags().StringP("api", "a", "", "The gitlab api url")
	runCmd.Flags().StringP("project", "i", "", "The gitlab project id")
	runCmd.Flags().BoolP("empty", "e", false, "Include empty subnets")
	runCmd.Flags().Bool("pseudo", true, "Include the network and broadcast addresses of all subnets. Useful if firewall rules handle the complete parent subnet.")
	runCmd.MarkFlagRequired("zone")
	runCmd.MarkFlagRequired("pat")
	runCmd.MarkFlagRequired("api")
	runCmd.MarkFlagRequired("project")
}
