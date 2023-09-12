package helper

import (
	"encoding/binary"
	"fmt"
	"math"
	"net"
	"net/netip"
)

type Label struct {
	Subnet string `json:"subnet"`
	Label  string `json:"label"`
	Color  string `json:"color"`
}

type SubnetResponse struct {
	Net     string
	Section string
	Empty   bool
}

type ByNet []SubnetResponse

func (a ByNet) Len() int { return len(a) }
func (a ByNet) Less(i, j int) bool {
	x, _, _ := net.ParseCIDR(a[i].Net)
	y, _, _ := net.ParseCIDR(a[j].Net)
	n := netip.MustParseAddr(x.String())
	m := netip.MustParseAddr(y.String())
	return n.Less(m)
}
func (a ByNet) Swap(i, j int) {
	a[i], a[j] = a[j], a[i]
}
func contains(subnet, route string) (bool, error) {
	sIP, sNW, err := net.ParseCIDR(subnet)
	if err != nil {
		return false, err
	}

	_, rNW, err := net.ParseCIDR(route)
	if err != nil {
		return false, err
	}

	sNWMaskSize, _ := sNW.Mask.Size()
	rNWMaskSize, _ := rNW.Mask.Size()

	return rNW.Contains(sIP) && sNWMaskSize >= rNWMaskSize, nil
}
func Hosts(ipnet *net.IPNet, pseudo bool) ([]string, error) {
	ip := ipnet.IP
	var ips []string
	for ip := ip.Mask(ipnet.Mask); ipnet.Contains(ip); inc(ip) {
		ips = append(ips, ip.String())
	}
	if pseudo {
		return ips, nil
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

func Subnets(zone string, newMask int) ([]*net.IPNet, error) {
	_, parent, err := net.ParseCIDR(zone)
	if err != nil {
		return nil, err
	}
	oldLength, _ := parent.Mask.Size()
	networkLength := newMask

	var subnets []*net.IPNet
	n := int(math.Pow(2, float64(networkLength-oldLength)))
	for i := 0; i < n; i++ {
		ip4 := parent.IP.To4()
		if ip4 != nil {
			n := binary.BigEndian.Uint32(ip4)
			n += uint32(i) << uint(32-networkLength)
			subnetIP := make(net.IP, len(ip4))
			binary.BigEndian.PutUint32(subnetIP, n)

			subnets = append(subnets, &net.IPNet{
				IP:   subnetIP,
				Mask: net.CIDRMask(networkLength, 32),
			})
		} else {
			return nil, fmt.Errorf("unexpected IP address type: %s", parent)
		}
	}

	return subnets, nil
}
