'use strict';
'require rpc';
'require form';
'require network';

var callFileRead = rpc.declare({
	object: 'file',
	method: 'read',
	params: [ 'path' ],
	expect: { data: '' },
	filter: function(value) { return value.trim() }
});

network.registerPatternVirtual(/^n2n-.+$/);

return network.registerProtocol('n2n', {
	getI18n: function() {
		return _('N2N VPN');
	},

	getIfname: function() {
		return this._ubus('l3_device') || 'n2n-%s'.format(this.sid);
	},

	getOpkgPackage: function() {
		return 'n2n-edge';
	},

	isFloating: function() {
		return true;
	},

	isVirtual: function() {
		return true;
	},

	getDevices: function() {
		return null;
	},

	containsDevice: function(ifname) {
		return (network.getIfnameOf(ifname) == this.getIfname());
	},

	renderFormOptions: function(s) {
		var dev = this.getL3Device() || this.getDevice(), o;

		o = s.taboption('general', form.DynamicList, 'server', _('Supernode address'), _('The format is [Address]:[Port]<br/>For example: 192.168.1.1:3333 or supernode.ntop.org:7777'));
		o.datatype = 'hostport';
		o.rmempty = false;

		o = s.taboption('general', form.Value, 'community', _('Community Name'));
		o.rmempty = false;
		o.password = true;

		o = s.taboption('general', form.ListValue, 'cipher_suite', _('Cipher suite'));
		o.default = 'A4';
		o.value('A1', _('None'));
		o.value('A2', _('Twofish'));
		o.value('A3', _('AES-CBC(deprecated)'));
		o.value('A4', _('ChaCha20'));
		o.value('A5', _('Speck-CTR'));

		o = s.taboption('general', form.Value, 'key', _('Key'));
		o.depends("cipher_suite","A2");
		o.depends("cipher_suite","A3");
		o.depends("cipher_suite","A4");
		o.depends("cipher_suite","A5");
		o.rmempty = false;
		o.password = true;

		o = s.taboption('general', form.ListValue, 'mode4', _('Interface mode'));
		o.value('static', _('Static'));
		o.value('dhcp', _('DHCP'));
		o.value('auto', _('Auto IP'));

		o = s.taboption('general', form.Value, 'ipaddr', _('IPv4 address'));
		o.datatype = 'ip4addr';
		o.rmempty = false;
		o.depends("mode4","static");

		o = s.taboption('general', form.Value, 'netmask', _('IPv4 netmask'));
		o.placeholder = '255.255.255.0';
		o.datatype = 'ip4addr';
		o.depends("mode4","static");

		o = s.taboption('general', form.Value, 'gateway', _('IPv4 gateway'));
		o.datatype = 'ip4addr';
		o.depends("mode4","static");

		o = s.taboption('general', form.Value, 'hostname', _('Hostname to send when requesting DHCP'));
		o.datatype = 'hostname';
		o.depends("mode4","dhcp");
		o.load = function(section_id) {
			return callFileRead('/proc/sys/kernel/hostname').then(L.bind(function(hostname) {
				this.placeholder = hostname;
				return form.Value.prototype.load.apply(this, [section_id]);
			}, this));
		};

		o = s.taboption('general', form.Flag, 'broadcast', _('Use broadcast flag'), _('Required for certain ISPs, e.g. Charter with DOCSIS 3'));
		o.depends("mode4","dhcp");

		o = s.taboption('general', form.Flag, 'defaultroute', _('Use default gateway'), _('If unchecked, no default route is configured'));
		o.depends("mode4","dhcp");

		o = s.taboption('general', form.Flag, 'peerdns', _('Use DNS servers advertised by peer'), _('If unchecked, the advertised DNS server addresses are ignored'));
		o.depends("mode4","dhcp");

		o = s.taboption('general', form.DynamicList, 'dns', _('Use custom DNS servers'));
		o.depends("peerdns","0");
		o.depends("mode4","static");
		o.datatype = 'ip4addr';
		o.cast = 'string';

		o = s.taboption('general', form.Value, 'metric', _('Metric'));
		o.placeholder = "0";
		o.datatype = 'uinteger';

		o = s.taboption('general', form.Value, 'clientid', _('Client ID to send when requesting DHCP'));
		o.depends("mode4","dhcp");
		o.datatype = 'hexstring';

		o = s.taboption('general', form.Value, 'vendorid', _('Vendor Class to send when requesting DHCP'));
		o.depends("mode4","dhcp");

		/*o = s.taboption('general', form.ListValue, 'mode6', _('IPv6 mode'));
		o.value('none', _('None'));
		o.value('static', _('Static'));
		o.value('dhcp', _('DHCPv6'));

		o = s.taboption('general', form.Value, 'ip6addr', _('IPv6 address'));
		o.datatype = 'ip6addr';
		o.depends("mode6","static");

		o = s.taboption('general', form.Value, 'ip6prefixlen', _('IPv6 prefix length'));
		o.placeholder = "64";
		o.datatype = 'max(128)';
		o.depends("mode6","static");

		o = s.taboption('general', form.Value, 'ip6gw', _('IPv6 gateway'));
		o.datatype = 'ip6addr';
		o.depends("mode6","static");

		o = s.taboption('general', form.ListValue, 'reqaddress', _('Request IPv6-address'));
		o.value('try');
		o.value('force');
		o.value('none', 'disabled');
		o.default = 'try';
		o.depends("mode6","dhcp");

		o = s.taboption('general', form.Value, 'reqprefix', _('Request IPv6-prefix of length'));
		o.value('auto', _('Automatic'));
		o.value('no', _('disabled'));
		o.value('48');
		o.value('52');
		o.value('56');
		o.value('60');
		o.value('64');
		o.default = 'auto';
		o.depends("mode6","dhcp");

		o = s.taboption('general', form.Flag, 'defaultroute6', _('Use default gateway'), _('If unchecked, no default route is configured'));
		o.depends("mode6","dhcp");

		o = s.taboption('general', form.DynamicList, 'ip6prefix', _('Custom delegated IPv6-prefix'));
		o.datatype = 'cidr6';
		o.depends("mode6","dhcp");

		o = s.taboption('general', form.Flag, 'peerdns6', _('Use DNS servers advertised by peer'), _('If unchecked, the advertised DNS server addresses are ignored'));
		o.depends("mode6","dhcp");

		o = s.taboption('general', form.DynamicList, 'dns6', _('Use custom DNS servers'));
		o.depends("peerdns6","0");
		o.depends("mode6","static");
		o.datatype = 'ip6addr';
		o.cast = 'string';

		o = s.taboption('general', form.Value, 'clientid6', _('Client ID to send when requesting DHCP'));
		o.datatype  = 'hexstring';
		o.depends("mode6","dhcp");

		o = s.taboption('general', form.Value, 'metric6', _('Metric'));
		o.placeholder = "0";
		o.datatype = 'uinteger';
		o.depends("mode6","static");*/

		o = s.taboption('advanced', form.Value, 'mac', _('MAC Address'));
		o.datatype = 'macaddr';
		o.placeholder = dev ? (dev.getMAC() || '') : '';

		o = s.taboption('advanced', form.Value, 'mtu_n2n', _('Override MTU'));
		o.placeholder = dev ? (dev.getMTU() || '1440') : '1440';
		o.datatype = 'max(9200)';

		o = s.taboption('advanced', form.Value, 'reg_interval', _('Registration interval'), _("For NAT hole punching (default 20 seconds)"));
		o.placeholder = "20";
		o.datatype = 'uinteger';

		o = s.taboption('advanced', form.Value, 'reg_ttl', _('TTL'), _("For registration packet when UDP NAT hole punching through supernode (default 0 for not set)"));
		o.placeholder = "0";
		o.datatype = 'uinteger';

		o = s.taboption('advanced', form.Value, 'bind_addr', _('Bind UDP port and IP'), _('Bind local UDP port and local IP address only (IP address is optional,the default is any)<br/>For example: 192.168.1.1:3333 or 3333'));
		o.datatype = 'or(ip4addrport, port)';

		o = s.taboption('advanced', form.Value, 'mgmtport', _('Management UDP Port'), _("For multiple edges on a machine"));
		o.datatype = 'port';

		o = s.taboption('advanced', form.Flag, 'forwarding', _('Enable packet forwarding through n2n community'));
		o.default = '1';

		o = s.taboption('advanced', form.Flag, 'header', _('Enable full header encryption'), _('Requires supernode with fixed community'));
		o.default = '1';

		o = s.taboption('advanced', form.Flag, 'comp', _('Enable compression'), _("Enable LZO(1x) compression for outgoing data packets"));

		o = s.taboption('advanced', form.Flag, 'verbose', _('Enable Verbose logging'));

		o = s.taboption('advanced', form.Flag, 'pmtu', _('Enable PMTU discovery'), _("PMTU discovery can reduce fragmentation but causes connections stall when not properly supported"));

		o = s.taboption('advanced', form.Flag, 'nop2p', _('Disable P2P connect'), _("Do not connect P2P. Always use the supernode"));

		o = s.taboption('advanced', form.Flag, 'multi', _('Enable multicast MAC addresses'));
	}
});
