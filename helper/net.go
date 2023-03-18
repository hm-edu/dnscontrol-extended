package helper

import (
	"encoding/binary"
	"fmt"
	"math"
	"net"
)

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
