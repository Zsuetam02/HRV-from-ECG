<?xml version='1.0' encoding='UTF-8'?>
<Project Type="Project" LVVersion="25008000">
	<Property Name="NI.LV.All.SaveVersion" Type="Str">25.0</Property>
	<Property Name="NI.LV.All.SourceOnly" Type="Bool">true</Property>
	<Item Name="My Computer" Type="My Computer">
		<Property Name="server.app.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.control.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.tcp.enabled" Type="Bool">false</Property>
		<Property Name="server.tcp.port" Type="Int">0</Property>
		<Property Name="server.tcp.serviceName" Type="Str">My Computer/VI Server</Property>
		<Property Name="server.tcp.serviceName.default" Type="Str">My Computer/VI Server</Property>
		<Property Name="server.vi.callsEnabled" Type="Bool">true</Property>
		<Property Name="server.vi.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="specify.custom.address" Type="Bool">false</Property>
		<Item Name="Control 1.ctl" Type="VI" URL="../Control 1.ctl"/>
		<Item Name="filterAndRRPeaksDet.vi" Type="VI" URL="../filterAndRRPeaksDet.vi"/>
		<Item Name="HRVcalc.vi" Type="VI" URL="../HRVcalc.vi"/>
		<Item Name="input.vi" Type="VI" URL="../input.vi"/>
		<Item Name="linearAnalysis.vi" Type="VI" URL="../linearAnalysis.vi"/>
		<Item Name="main.vi" Type="VI" URL="../main.vi"/>
		<Item Name="signalWithPeaks.vi" Type="VI" URL="../signalWithPeaks.vi"/>
		<Item Name="Dependencies" Type="Dependencies"/>
		<Item Name="Build Specifications" Type="Build"/>
	</Item>
</Project>
