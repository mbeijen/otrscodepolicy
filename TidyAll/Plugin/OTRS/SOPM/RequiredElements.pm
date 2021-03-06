# --
# TidyAll/Plugin/OTRS/SOPM/RequiredElements.pm - code quality plugin
# Copyright (C) 2001-2013 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package TidyAll::Plugin::OTRS::SOPM::RequiredElements;

use strict;
use warnings;

use base qw(TidyAll::Plugin::OTRS::Base);

sub validate_source {    ## no critic
    my ( $Self, $Code ) = @_;

    return if $Self->IsPluginDisabled( Code => $Code );

    my $ErrorMessage;

    my $Name            = 0;
    my $Version         = 0;
    my $Counter         = 0;
    my $Framework       = 0;
    my $Vendor          = 0;
    my $URL             = 0;
    my $License         = 0;
    my $BuildDate       = 0;
    my $BuildHost       = 0;
    my $DescriptionDE   = 0;
    my $DescriptionEN   = 0;
    my $Table           = 0;
    my $DatabaseUpgrade = 0;
    my $NameLength      = 0;

    my @CodeLines = split /\n/, $Code;

    for my $Line (@CodeLines) {
        $Counter++;
        if ( $Line =~ /<Name>[^<>]+<\/Name>/ ) {
            $Name = 1;
        }
        elsif ( $Line =~ /<Description Lang="en">[^<>]+<\/Description>/ ) {
            $DescriptionEN = 1;
        }
        elsif ( $Line =~ /<Description Lang="de">[^<>]+<\/Description>/ ) {
            $DescriptionDE = 1;
        }
        elsif ( $Line =~ /<License>([^<>]+)<\/License>/ ) {
            $License = 1;
        }
        elsif ( $Line =~ /<URL>([^<>]+)<\/URL>/ ) {
            $URL = 1;
        }
        elsif ( $Line =~ /<BuildHost>[^<>]*<\/BuildHost>/ ) {
            $BuildHost = 1;
        }
        elsif ( $Line =~ /<BuildDate>[^<>]*<\/BuildDate>/ ) {
            $BuildDate = 1;
        }
        elsif ( $Line =~ /<Vendor>([^<>]+)<\/Vendor>/ ) {
            $Vendor = 1;
        }
        elsif ( $Line =~ /<Framework>([^<>]+)<\/Framework>/ ) {
            $Framework = 1;
        }
        elsif ( $Line =~ /<Version>([^<>]+)<\/Version>/ ) {
            $Version = 1;
        }
        elsif ( $Line =~ /<File([^<>]+)>([^<>]*)<\/File>/ ) {
            my $Attributes = $1;
            my $Content    = $2;
            if ( $Content ne '' ) {
                $ErrorMessage .= "Don't insert something between <File><\/File>!\n";
            }
            if ( $Attributes =~ /(Type|Encode)=/ ) {
                $ErrorMessage .= "Don't use the attribute 'Type' or 'Encode' in <File>Tags!\n";
            }
            if ( $Attributes =~ /Location=.+?\.sopm/ ) {
                $ErrorMessage .= "It is senseless to include .sopm-files in a opm! -> $Line";
            }
        }
        elsif ( $Line =~ /(<Table .+?>|<\/Table>)/ ) {
            $Table = 1;
        }
        elsif ( $Line =~ /<DatabaseUpgrade>/ ) {
            $DatabaseUpgrade = 1;
        }
        elsif ( $Line =~ /<\/DatabaseUpgrade>/ ) {
            $DatabaseUpgrade = 0;
        }
        elsif ( $Line =~ /<Table.+?>/ ) {
            if ( $DatabaseUpgrade && $Line =~ /<Table/ && $Line !~ /Version=/ ) {
                $ErrorMessage
                    .= "If you use <Table... in a <DatabaseUpgrade> context you need to have a Version attribute with the beginning version where this change is needed (e. g. <TableAlter Name=\"some_table\" Version=\"1.0.6\">)!\n";
            }
        }

        if ( $Line =~ /<(Column.*|TableCreate.*) Name="(.+?)"/ ) {
            $Name = $2;
            if ( length $Name > 30 ) {
                $NameLength .= "Line $Counter: $Name\n";
            }
        }
    }

    if ($Table) {
        $ErrorMessage
            .= "The Element <Table> is not allowed in sopm-files. Perhaps you mean <TableCreate>!\n";
    }
    if ($BuildDate) {
        $ErrorMessage .= "<BuildDate> no longer used in .sopms!\n";
    }
    if ($BuildHost) {
        $ErrorMessage .= "<BuildHost> no longer used in .sopms!\n";
    }

    #if (!$DescriptionDE) {
    #    $ErrorMessage .= "You have forgot to use the element <Description Lang=\"de\">!\n";
    #}
    if ( !$DescriptionEN ) {
        $ErrorMessage .= "You have forgot to use the element <Description Lang=\"en\">!\n";
    }
    if ( !$Name ) {
        $ErrorMessage .= "You have forgot to use the element <Name>!\n";
    }
    if ( !$Version ) {
        $ErrorMessage .= "You have forgot to use the element <Version>!\n";
    }
    if ( !$Framework ) {
        $ErrorMessage .= "You have forgot to use the element <Framework>!\n";
    }
    if ( !$Vendor ) {
        $ErrorMessage .= "You have forgot to use the element <Vendor>!\n";
    }
    if ( !$URL ) {
        $ErrorMessage .= "You have forgot to use the element <URL>!\n";
    }
    if ( !$License ) {
        $ErrorMessage .= "You have forgot to use the element <License>!\n";
    }
    if ($NameLength) {
        $ErrorMessage .= "Please use Column and Tablenames with less than 24 letters!\n";
        $ErrorMessage .= $NameLength;
    }
    if ($ErrorMessage) {
        die __PACKAGE__ . "\n" . $ErrorMessage;
    }

    return;
}

1;
