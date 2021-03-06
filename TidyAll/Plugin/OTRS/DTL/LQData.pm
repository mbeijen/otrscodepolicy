# --
# TidyAll/Plugin/OTRS/DTL/LQData.pm - code quality plugin
# Copyright (C) 2001-2013 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package TidyAll::Plugin::OTRS::DTL::LQData;

use strict;
use warnings;

use base qw(TidyAll::Plugin::OTRS::Base);

sub validate_source {    ## no critic
    my ( $Self, $Code ) = @_;

    return $Code if $Self->IsPluginDisabled( Code => $Code );
    return if $Self->IsFrameworkVersionLessThan( 3, 2 );

    my $Counter;
    my $ErrorMessage;

    for my $Line ( split /\n/, $Code ) {
        $Counter++;

        # next if IE behavior need to get ignored
        # see bug#5579 - Spaces in filenames are converted to + characters when downloading in IE.
        next if $Line =~ /href="\$Env{"CGIHandle"}\/\$QData{"Filename"}?/;

        # next if links for agent/customer iface for cockpit is used
        # see bug #6172 - Agent/Customer Interface links to instance broken
        next if $Line =~ m{href="\$QData{" (?: (?: Agent | Customer ) Link | Destination ) "}}xms;

        # allow the usage of QData if the line is commented out. Otherwise commenting out inherited
        # code (OldId) doesn't work and the filter still complains about the usage of QData in
        # href, although the code itself isn't effective at all
        next if $Line =~ m{^[\t ]*\#}xms;

        # now check href attribute
        if ( $Line !~ /href="(|#)"/i && $Line =~ /href=(.+?)[ >]/i ) {
            if ( $1 =~ /=\$QData/si ) {
                $ErrorMessage .= __PACKAGE__
                    . ": please check, use \$LQData instead of \$QData in a href string Line $Counter ($Line)\n";
            }
        }
    }

    if ($ErrorMessage) {
        die __PACKAGE__ . "\n$ErrorMessage";
    }
}

1;
