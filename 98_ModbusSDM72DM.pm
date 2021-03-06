##############################################
# $Id: 98_ModbusSDM72DM.pm 
#
#	fhem Modul für Stromzähler SDM72-D-M von B+G E-Tech & EASTON
#	verwendet Modbus.pm als Basismodul für die eigentliche Implementation des Protokolls.
#
#  by A. Hermann
#
##############################################################################
#	Changelog:
#	2018-04-03	initial release

package main;

use strict;
use warnings;
use Time::HiRes qw( time );

sub ModbusSDM72DM_Initialize($);

# deviceInfo defines properties of the device.
# some values can be overwritten in parseInfo, some defaults can even be overwritten by the user with attributes if a corresponding attribute is added to AttrList in _Initialize.
#
my %SDM72DMdeviceInfo = (
	"timing"	=>	{
			timeout		=>	2,		# 2 seconds timeout when waiting for a response
			commDelay	=>	0.7,	# 0.7 seconds minimal delay between two communications e.g. a read a the next write,
									# can be overwritten with attribute commDelay if added to AttrList in _Initialize below
			sendDelay	=>	0.7,	# 0.7 seconds minimal delay between two sends, can be overwritten with the attribute
									# sendDelay if added to AttrList in _Initialize function below
			}, 
	"i"			=>	{				# details for "input registers" if the device offers them
			read		=>	4,		# use function code 4 to read discrete inputs. They can not be read by definition.
			defLen		=>	2,		# default length (number of registers) per value ((e.g. 2 for a float of 4 bytes that spans 2 registers)
									# can be overwritten in parseInfo per reading by specifying the key "len"
			combine		=>	40,		# allow combined read of up to 10 adjacent registers during getUpdate
#			combine		=>	1,		# no combined read (read more than one registers with one read command) during getUpdate
			defFormat	=>	"%.1f",	# default format string to use after reading a value in sprintf
									# can be overwritten in parseInfo per reading by specifying the key "format"
			defUnpack	=>	"f>",	# default pack / unpack code to convert raw values, e.g. "n" for a 16 bit integer oder
									# "f>" for a big endian float IEEE 754 floating-point numbers
									# can be overwritten in parseInfo per reading by specifying the key "unpack"
			defPoll		=>	1,		# All defined Input Registers should be polled by default unless specified otherwise in parseInfo or by attributes
			defShowGet	=>	1,		# default für showget Key in parseInfo
			},
	"h"			=>	{				# details for "holding registers" if the device offers them
			read		=>	3,		# use function code 3 to read holding registers.
			write		=>	16,		# use function code 6 to write holding registers (alternative could be 16)
			defLen		=>	2,		# default length (number of registers) per value (e.g. 2 for a float of 4 bytes that spans 2 registers)
									# can be overwritten in parseInfo per reading by specifying the key "len"
			combine		=>	10,		# allow combined read of up to 10 adjacent registers during getUpdate
			defUnpack	=>	"f>",	# default pack / unpack code to convert raw values, e.g. "n" for a 16 bit integer oder
									# "f>" for a big endian float IEEE 754 floating-point numbers
									# can be overwritten in parseInfo per reading by specifying the key "unpack"
			defShowGet	=>	1,		# default für showget Key in parseInfo
			},
);

# %parseInfo:
# r/c/i+adress => objHashRef (h = holding register, c = coil, i = input register, d = discrete input)
# the address is a decimal number without leading 0
#
# Explanation of the parseInfo hash sub-keys:
# name			internal name of the value in the modbus documentation of the physical device
# reading		name of the reading to be used in Fhem
# set			can be set to 1 to allow writing this value with a Fhem set-command
# setmin		min value for input validation in a set command
# setmax		max value for input validation in a set command
# hint			string for fhemweb to create a selection or slider
# expr			perl expression to convert a string after it has bee read
# map			a map string to convert an value from the device to a more readable output string 
# 				or to convert a user input to the machine representation
#				e.g. "0:mittig, 1:oberhalb, 2:unterhalb"				
# setexpr		per expression to convert an input string to the machine format before writing
#				this is typically the reverse of the above expr
# format		a format string for sprintf to format a value read
# len			number of Registers this value spans
# poll			defines if this value is included in the read that the module does every defined interval
#				this can be changed by a user with an attribute
# unpack		defines the translation between data in the module and in the communication frame
#				see the documentation of the perl pack function for details.
#				example: "n" for an unsigned 16 bit value or "f>" for a float that is stored in two registers
# showget		can be set to 1 to allow a Fhem get command to read this value from the device
# polldelay		if a value should not be read in each iteration after interval has passed, 
#				this value can be set to a multiple of interval

my %SDM72DMparseInfo = (
# Summenwerte Leistung, bei jedem Zyklus
	"i52"	=>	{	# input register 0x0034
					name		=> "Total system power",	# internal name of this register in the hardware doc
					reading		=> "Power_Sum__W",			# name of the reading for this value
#					format		=> '%.1f W',				# format string for sprintf
					format		=> '%.1f',					# format string for sprintf
				},
# kWh Gesamtwerte, bei jedem Zyklus  #nur bei jedem 11. Zyklus
	"i342"	=>	{	# input register 0x0156
					name		=> "Total kWh",				# internal name of this register in the hardware doc
					reading		=> "Energy_total__kWh",		# name of the reading for this value
#					format		=> '%.3f kWh',				# format string for sprintf
					format		=> '%.3f',					# format string for sprintf
#					polldelay	=> 60,						# request only if last read is older than 60 seconds
#					polldelay	=> "x11",					# only poll this Value if last read is older than x*Iteration, otherwiese getUpdate will skip it
				},


###############################################################################################################
# Holding Register
###############################################################################################################
	"h58"	=>	{
					name		=> "Time of back light",			# internal name of this register in the hardware doc
					reading		=> "Time__bl",	# name of the reading for this value
#					format		=> '%.f min',				# format string for sprintf
					format		=> '%.f',					# format string for sprintf
					min			=> 0,						# input validation for set: min value
					max			=> 120,						# input validation for set: max value
					poll		=> "once",					# only poll once after define (or after a set)
					set			=> 1,						# this value can be set
				},

	"h20"	=>	{	# holding register 0x0014
					# Write the network port node address: 1 to 247 for MODBUS Protocol, default 1.
					# Requires a restart to become effective.
					name		=> "Network Node",			# internal name of this register in the hardware doc
					reading		=> "Modbus_Node_adr",		# name of the reading for this value
					min			=> 1,						# input validation for set: min value
					max			=> 247,						# input validation for set: max value
					format		=> '%u',					# format string for sprintf
					poll		=> "once",					# only poll once after define (or after a set)
					set			=> 1,						# this value can be set
				},

# Ende parseInfo
);


#####################################
sub
ModbusSDM72DM_Initialize($)
{
    my ($modHash) = @_;

	require "$attr{global}{modpath}/FHEM/98_Modbus.pm";

	$modHash->{parseInfo}  = \%SDM72DMparseInfo;			# defines registers, inputs, coils etc. for this Modbus Defive

	$modHash->{deviceInfo} = \%SDM72DMdeviceInfo;			# defines properties of the device like 
															# defaults and supported function codes

	ModbusLD_Initialize($modHash);							# Generic function of the Modbus module does the rest

	$modHash->{AttrList} = $modHash->{AttrList} . " " .		# Standard Attributes like IODEv etc 
		$modHash->{ObjAttrList} . " " .						# Attributes to add or overwrite parseInfo definitions
		$modHash->{DevAttrList} . " " .						# Attributes to add or overwrite devInfo definitions
		"poll-.* " .										# overwrite poll with poll-ReadingName
		"polldelay-.* ";									# overwrite polldelay with polldelay-ReadingName
}


1;

=pod
=begin html

<a name="ModbusSDM72DM"></a>
<h3>ModbusSDM72DM</h3>
<ul>
    ModbusSDM72DM uses the low level Modbus module to provide a way to communicate with SDM72DM smart electrical meter from B+G E-Tech & EASTON.
	It defines the modbus input and holding registers and reads them in a defined interval.
	
	<br>
    <b>Prerequisites</b>
    <ul>
        <li>
          This module requires the basic Modbus module which itsef requires Device::SerialPort or Win32::SerialPort module.
        </li>
    </ul>
    <br>

    <a name="ModbusSDM72DMDefine"></a>
    <b>Define</b>
    <ul>
        <code>define &lt;name&gt; ModbusSDM72DM &lt;Id&gt; &lt;Interval&gt;</code>
        <br><br>
        The module connects to the smart electrical meter with Modbus Id &lt;Id&gt; through an already defined modbus device and actively requests data from the 
        smart electrical meter every &lt;Interval&gt; seconds <br>
        <br>
        Example:<br>
        <br>
        <ul><code>define SDM72DM ModbusSDM72DM 1 60</code></ul>
    </ul>
</ul>

=end html
=cut
