our (%global, @test, $q);
package system::reports;
@ISA = qw(system);
use strict;


# perl index.cgi tier1=system name=reports gc_navigator=1
# perl index.cgi tier1=system name=reports pla_spreadsheet=1
# perl index.cgi tier1=system name=reports hs_name_check=1
# perl index.cgi tier1=system name=reports rapid_insight_export=1
# perl index.cgi tier1=system name=reports hs_certificates=1
# perl index.cgi tier1=system name=reports convention_list=1
# perl index.cgi tier1=system name=reports run=moodle_test_list
# perl index.cgi tier1=system name=reports run=naccap_addresses
# perl index.cgi tier1=system name=reports run=noellevitz
# perl index.cgi tier1=system name=reports run=NRCCRU_Match
# perl index.cgi tier1=system name=reports run=paper_vs_web_app
# perl index.cgi tier1=system name=reports run=tests_needed
# perl index.cgi tier1=system name=reports run=tier_calibrate
# perl index.cgi tier1=system name=reports run=tier_assignment
# perl index.cgi tier1=system name=reports run=populate_demographics
# perl index.cgi tier1=system name=reports run=snap_shot
# perl index.cgi tier1=system name=reports run=sibling_off_app
# perl index.cgi tier1=system name=reports year=2012 term=FA # Weekly report

# Web
# https://admission-web.goshen.edu/insite/system/reports
# https://admission-web.goshen.edu/insite/system/reports?gc_navigator=1


{ # encapsulate class data
	my @hidden_columns;
	my %_default_keys = (	# default	accessibility
		_hidden_col_array_ref =>	[\@hidden_columns, 'system::gm', '']	
	);

#	sub _system_data_keys_hash {
#		 (		# default	class	category
#			_primary_addr =>	['', 'system::gm','']
#		);
#	}

	# classwide default value for a specified object attribute
	sub _default_for {
		my ($self, $attr) = @_;
		return $_default_keys{$attr}[0] if exists $_default_keys{$attr};
		return $self->SUPER::_default_for($attr);
	}

	# list of names of all specified object attributes
	sub _standard_keys {
		my ($self, %attr) = @_;
		($self->SUPER::_standard_keys(), keys %_default_keys);
	}

	sub _append_keys {
		my ($self, %arg) = @_;
		$self->SUPER::_append_keys(%arg);
		my $value = 'system::gm::_'.$arg{call}.'_hash';
		if (exists &{$value}){
			my %add_hash = $self->$value();
			@_default_keys{ keys %add_hash } = values %add_hash; # only if the subroutine exists
		}
	}
}

# required classes
sub self_starter {
#	my ($self, $attr) = @_;
}

sub weekly_report {
	# main::printer ('working');
	my @build;
	my $date = main::strftime('%D %T',localtime);
	push @build, "$date\n\n";

	#open(OUT,">/home/amosmk/adm_mailings/report.txt");
	#open(OUT,">$global{g_path}reports/2011_fa.txt");
	#print OUT 'hello';
	my $date_;

	my ($major, %major, %inq, %lead, %defapply, %apply, %defadmit, %admit, %defdeposit, %deposit, %deny, %withdrawn, %cancel);
	my (%cur_inq, %cur_lead, %cur_apply, %cur_admit, %cur_deposit);
	push my @archive, "id_num\tfirst\tlast\tyear\tterm\tstage\ttype\n";
	my $sth = $global{dbh_jenz}->prepare (qq{
		select n.id_num, first_name, last_name, prog_cde, right(stage, 3) stage, load_p_f, substring(stage, 3, 1) stage2, yr_cde, trm_cde, isnull(candidacy_type, 'F') type, last_name, first_name, load_p_f, isnull(c.udef_1a_2, '') undocumented,
		citizen_of, convert(varchar(12), getdate(), 112) date_stamp,
		(select 1 from candidate_udf
		where id_num = n.id_num and
		legacy = 'Y'
		) legacy
		from name_master n, candidacy cd, candidate c, biograph_master b
		where
		n.id_num = cd.id_num and
		n.id_num = c.id_num and
		n.id_num = b.id_num and
		yr_cde = ? and
		trm_cde = ? and
		-- source_1 = 'ifcol' and
		/* (source_2 = 'ifcol' or
		source_3 = 'ifcia' or
		source_4 = 'ifcia' or
		source_5 = 'ifcia' or
		source_6 = 'ifcia' or
		source_7 = 'ifcia' or
		source_8 = 'ifcia' or
		source_9 = 'ifcia' or
		source_10 = 'ifcia') and */
		/* exists ( select 1 from address_master
			where
			id_num = n.id_num and
			addr_cde = '*lhp' and
			state = 'ks'
		) and */
		isnull(load_p_f, '') <> 'p' and
		isnull(dept_cde, '') <> 'GAP' and
		isnull(name_sts, '') <> 'D' /* and
		right(stage, 3) >= 100 */
			});
	$sth->execute ($q->param('year'), $q->param('term'));
	while (my $contact_ref = $sth->fetchrow_hashref ()){
		$date_ = "$contact_ref->{date_stamp}-$contact_ref->{yr_cde}-$contact_ref->{trm_cde}";
		if ($contact_ref->{undocumented} eq 'U'){ #  || $contact_ref->{citizen_of} eq 'CA'
			if ($contact_ref->{type} eq 'I'){
				$contact_ref->{type} = 'F'
			} elsif ($contact_ref->{type} eq 'K'){
				$contact_ref->{type} = 'R'
			} elsif ($contact_ref->{type} eq 'V'){
				$contact_ref->{type} = 'X'
			} elsif ($contact_ref->{type} eq 'J'){
				$contact_ref->{type} = 'T'
			}
		}
		if ($contact_ref->{type} =~ /[JKV]/){
			$contact_ref->{type} = 'INT';
		}
		$major{$contact_ref->{prog_cde}}++;
		$inq{$contact_ref->{type}}++; 
		$major->{'inq'.$contact_ref->{prog_cde}}{$contact_ref->{type}}++;
		if ($contact_ref->{stage} < 400){
			if ($contact_ref->{stage} >= 160 || $contact_ref->{legacy}){
				$cur_lead{$contact_ref->{type}}++ unless $contact_ref->{stage} =~ /9\d$/;
			} else {
				$cur_inq{$contact_ref->{type}}++ unless $contact_ref->{stage} =~ /9\d$/;
			}
		}
		$lead{$contact_ref->{type}}++ if $contact_ref->{stage} >= 160 || $contact_ref->{legacy};
		$major->{'lead'.$contact_ref->{prog_cde}}{$contact_ref->{type}}++ if $contact_ref->{stage} >= 160 || $contact_ref->{legacy};
		next if $contact_ref->{stage} < 400;

		unless ($contact_ref->{type}){
			main::printer("$contact_ref->{first_name} $contact_ref->{last_name} needs a type", 'output');
			next;
		}
		push @archive, "$contact_ref->{id_num}\t$contact_ref->{first_name}\t$contact_ref->{last_name}\t$contact_ref->{yr_cde}\t$contact_ref->{trm_cde}\t$contact_ref->{stage}\t$contact_ref->{type}\n";
		unless ($contact_ref->{load_p_f}){
			main::printer("$contact_ref->{first_name} $contact_ref->{last_name} needs the full/part field completed", 'output');
		}

		if ($contact_ref->{stage} >= 400){ 
		#	if ($contact_ref->{stage} =~ /480|680|780/){
		#		$defapply{$contact_ref->{type}}++; 
		#		$major->{'defapply'.$contact_ref->{prog_cde}}{$contact_ref->{type}}++;
		#	} else {
				$apply{$contact_ref->{type}}++; 
				$cur_apply{$contact_ref->{type}}++ unless $contact_ref->{stage} =~ /8\d$/ || $contact_ref->{stage} =~ /9\d$/ || $contact_ref->{stage} >= 600; 
				$major->{'apply'.$contact_ref->{prog_cde}}{$contact_ref->{type}}++;
		#	}
		}
		if ($contact_ref->{stage} >= 600){ 
		#	if ($contact_ref->{stage} =~ /680|780/){
		#		$defadmit{$contact_ref->{type}}++; 
		#		$major->{'defadmit'.$contact_ref->{prog_cde}}{$contact_ref->{type}}++;
		#	} else {
				$admit{$contact_ref->{type}}++; 
				$cur_admit{$contact_ref->{type}}++ unless $contact_ref->{stage} =~ /8\d$/ || $contact_ref->{stage} =~ /9\d$/ || $contact_ref->{stage} >= 700; 
				$major->{'admit'.$contact_ref->{prog_cde}}{$contact_ref->{type}}++;
		#	}
		}

		if ($contact_ref->{stage} =~ /590/){
			$deny{$contact_ref->{type}}++; 
			$major->{'deny'.$contact_ref->{prog_cde}}{$contact_ref->{type}}++;
		}

		if ($contact_ref->{stage} =~ /490/){
			$withdrawn{$contact_ref->{type}}++; 
			$major->{'withdrawn'.$contact_ref->{prog_cde}}{$contact_ref->{type}}++;
		}

		if ($contact_ref->{stage} =~ /690/){
			$withdrawn{$contact_ref->{type}}++; 
			$major->{'withdrawn'.$contact_ref->{prog_cde}}{$contact_ref->{type}}++;
		} 

		if ($contact_ref->{stage} >= 700){ 
		#	if ($contact_ref->{stage} =~ /780/){
		#		$defdeposit{$contact_ref->{type}}++; 
		#		$major->{'defdeposit'.$contact_ref->{prog_cde}}{$contact_ref->{type}}++;
		#	} else {
				$deposit{$contact_ref->{type}}++; 
				$cur_deposit{$contact_ref->{type}}++ unless $contact_ref->{stage} =~ /8\d$/ || $contact_ref->{stage} =~ /9\d$/ || $contact_ref->{stage} >= 800; 
				$major->{'deposit'.$contact_ref->{prog_cde}}{$contact_ref->{type}}++;
		#	}
		}
		if ($contact_ref->{stage} =~ /790/){
			$cancel{$contact_ref->{type}}++;
			$major->{'cancel'.$contact_ref->{prog_cde}}{$contact_ref->{type}}++;
		} 

	}

	local $^W; # turn off -w warming

	push @build, $q->param('year'), $q->param('term'), "\n";

	push @build, "First Year Student\n" .
	"	$cur_inq{F} / $inq{F} Total Inquiries\n" .
	"	$cur_lead{F} / $lead{F} Lead\n" .
	"	$cur_apply{F} / $apply{F} Applied\n" .
	"	$cur_admit{F} / $admit{F} Admitted\n" .
	"	$deny{F} Denied\n" .
	"	$withdrawn{F} Withdrawn\n" .
	"	$cur_deposit{F} / $deposit{F} Deposit\n" .
	"	$cancel{F} Cancel\n";	

	$sth = $global{dbh_jenz}->prepare (qq{
		insert into gsc_ad_funnel_rpt_hist 
		(archive_dte, yr_cde, trm_cde, prog_cde, candidacy_type, inquiries, leads, applied, admitted, denied, withdrawn, deposited, cancelled_deferred)
		values (getdate(), ?, ?, 'All', 'F', ?, ?, ?, ?, ?, ?, ?, ?)
			});
	$sth->execute ($q->param('year'), $q->param('term'), $inq{F} || 0, $lead{F} || 0, $apply{F} || 0, $admit{F} || 0, $deny{F} || 0, $withdrawn{F} || 0, $deposit{F} || 0, $cancel{F} || 0) if $q->param('load');
	
	push @build, "Transfer\n" .
	"	$cur_inq{T} / $inq{T} Total Inquiries\n" .
	"	$cur_lead{T} / $lead{T} Lead\n" .
	"	$cur_apply{T} / $apply{T} Applied\n" .
	"	$cur_admit{T} / $admit{T} Admitted\n" .
	"	$deny{T} Denied\n" .
	"	$withdrawn{T} Withdrawn\n" .
	"	$cur_deposit{T} / $deposit{T} Deposit\n" .
	"	$cancel{T} Cancel\n";	

	$sth = $global{dbh_jenz}->prepare (qq{
		insert into gsc_ad_funnel_rpt_hist 
		(archive_dte, yr_cde, trm_cde, prog_cde, candidacy_type, inquiries, leads, applied, admitted, denied, withdrawn, deposited, cancelled_deferred)
		values (getdate(), ?, ?, 'All', 'T', ?, ?, ?, ?, ?, ?, ?, ?)
			});
	$sth->execute ($q->param('year'), $q->param('term'), $inq{T} || 0, $lead{T} || 0, $apply{T} || 0, $admit{T} || 0, $deny{T} || 0, $withdrawn{T} || 0, $deposit{T} || 0, $cancel{T} || 0) if $q->param('load');

	push @build, "Readmit\n" .
	"	$cur_inq{R} / $inq{R} Total Inquiries\n" .
	"	$cur_lead{R} / $lead{R} Lead\n" .
	"	$cur_apply{R} / $apply{R} Applied\n" .
	"	$cur_admit{R} / $admit{R} Admitted\n" .
	"	$deny{R} Denied\n" .
	"	$withdrawn{R} Withdrawn\n" .
	"	$cur_deposit{R} / $deposit{R} Deposit\n" .
	"	$cancel{R} Cancel\n";	

	$sth = $global{dbh_jenz}->prepare (qq{
		insert into gsc_ad_funnel_rpt_hist 
		(archive_dte, yr_cde, trm_cde, prog_cde, candidacy_type, inquiries, leads, applied, admitted, denied, withdrawn, deposited, cancelled_deferred)
		values (getdate(), ?, ?, 'All', 'R', ?, ?, ?, ?, ?, ?, ?, ?)
			});
	$sth->execute ($q->param('year'), $q->param('term'), $inq{R} || 0, $lead{R} || 0, $apply{R} || 0, $admit{R} || 0, $deny{R} || 0, $withdrawn{R} || 0, $deposit{R} || 0, $cancel{R} || 0) if $q->param('load');


	my ($inq, $lead, $apply, $admit, $deny, $withdraw, $deposit, $cancel);
	my @criteria = qw/F T R/;
	
		foreach my $key (@criteria){
			$inq += $inq{$key};
			$lead += $lead{$key};
			$apply += $apply{$key};
			$admit += $admit{$key};
			$deny += $deny{$key};
			$withdraw += $withdrawn{$key};
			$deposit += $deposit{$key};
			$cancel += $cancel{$key};
		}
	
	push @build, "\nSub-Total\n" .
	"	$inq Inquiry\n" .
	"	$lead Lead\n" .
	"	$apply Apply\n" .
	"	$admit Admit\n" .
	"	$deny Deny\n" .
	"	$withdraw Withdraw\n" .
	"	$deposit Deposit\n" .
	"	$cancel Cancel\n\n";
	
	push @build, "International First Year\n" .
	"	$cur_inq{I} / $inq{I} Total Inquiries\n" .
	"	$cur_lead{I} / $lead{I} Lead\n" .
	"	$cur_apply{I} / $apply{I} Applied\n" .
	"	$cur_admit{I} / $admit{I} Admitted\n" .
	"	$deny{I} Denied\n" .
	"	$withdrawn{I} Withdrawn\n" .
	"	$cur_deposit{I} / $deposit{I} Deposit\n" .
	"	$cancel{I} Cancel\n\n";	

	$sth = $global{dbh_jenz}->prepare (qq{
		insert into gsc_ad_funnel_rpt_hist 
		(archive_dte, yr_cde, trm_cde, prog_cde, candidacy_type, inquiries, leads, applied, admitted, denied, withdrawn, deposited, cancelled_deferred)
		values (getdate(), ?, ?, 'All', 'N', ?, ?, ?, ?, ?, ?, ?, ?)
			});
	$sth->execute ($q->param('year'), $q->param('term'), $inq{I} || 0, $lead{I} || 0, $apply{I} || 0, $admit{I} || 0, $deny{I} || 0, $withdrawn{I} || 0, $deposit{I} || 0, $cancel{I} || 0) if $q->param('load');

	push @build, "International\n" .
	"	$inq{INT} Total Inquiries\n" .
	"	$lead{INT} Lead\n" .
	"	$apply{INT} Applied\n" .
	"	$admit{INT} Admitted\n" .
	"	$deny{INT} Denied\n" .
	"	$withdrawn{INT} Withdrawn\n" .
	"	$deposit{INT} Deposit\n" .
	"	$cancel{INT} Cancel\n";	

	$sth = $global{dbh_jenz}->prepare (qq{
		insert into gsc_ad_funnel_rpt_hist 
		(archive_dte, yr_cde, trm_cde, prog_cde, candidacy_type, inquiries, leads, applied, admitted, denied, withdrawn, deposited, cancelled_deferred)
		values (getdate(), ?, ?, 'All', 'I', ?, ?, ?, ?, ?, ?, ?, ?)
			});
	$sth->execute ($q->param('year'), $q->param('term'), $inq{INT} || 0, $lead{INT} || 0, $apply{INT} || 0, $admit{INT} || 0, $deny{INT} || 0, $withdrawn{INT} || 0, $deposit{INT} || 0, $cancel{INT} || 0) if $q->param('load');

		$inq += $inq{I};
		$lead += $lead{I};
		$apply += $apply{I};
		$admit += $admit{I};
		$deny += $deny{I};
		$withdraw += $withdrawn{I};
		$deposit += $deposit{I};
		$cancel += $cancel{I};

		$inq += $inq{INT};
		$lead += $lead{INT};
		$apply += $apply{INT};
		$admit += $admit{INT};
		$deny += $deny{INT};
		$withdraw += $withdrawn{INT};
		$deposit += $deposit{INT};
		$cancel += $cancel{INT};
	
	my $netdeposit = ($deposit - $cancel);
	push @build, "\nTotal\n" .
	"	$inq Inquiry\n" .
	"	$lead Lead\n" .
	"	$apply Apply\n" .
	"	$admit Admit\n" .
	"	$deny Deny\n" .
	"	$withdraw Withdraw\n" .
	"	$deposit Deposit\n" .
	"	$cancel Cancel\n" .
	"	$netdeposit Net Deposit\n\n";
	foreach (@build){
		s/\n/<br>/g;
		s/\t/&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;/g;
	}

	while (my ($name, $num) = each(%major)){
		foreach ('F','T','R','I','INT'){
			my $type = $_;
			$type = 'N' if $type eq 'I';
			$type = 'I' if $type eq 'INT';
			my $sth = $global{dbh_jenz}->prepare (qq{
				insert into gsc_ad_funnel_rpt_hist 
				(archive_dte, yr_cde, trm_cde, candidacy_type, prog_cde, inquiries, leads, applied, admitted, denied, withdrawn, deposited, cancelled_deferred)
				values (getdate(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
					});
			$sth->execute ($q->param('year'), $q->param('term'), $type || 0, $name || 0, $major->{'inq'.$name}{$type} || 0, $major->{'lead'.$name}{$type} || 0, $major->{'apply'.$name}{$type} || 0, $major->{'inq'.$admit}{$type} || 0, $major->{'deny'.$name}{$type} || 0, $major->{'withdrawn'.$name}{$type} || 0, $major->{'deposit'.$name}{$type} || 0, $major->{'cancel'.$name}{$type} || 0) if $q->param('load');
		}
	}

	exit if $q->param('load');

	# local $^W; # turn off strict flag
	# Common app numbers
	%inq = ();
	%lead = ();
	%defapply = ();
	%apply = ();
	%defadmit = ();
	%admit = ();
	%defdeposit = ();
	%deposit = ();
	%deny = ();
	%withdrawn = ();
	%cancel = ();
	$sth = $global{dbh_jenz}->prepare (qq{
		select n.id_num, first_name, last_name, right(stage, 3) stage, load_p_f, substring(stage, 3, 1) stage2, yr_cde, trm_cde, isnull(candidacy_type, 'F') type, last_name, first_name, load_p_f, isnull(c.udef_1a_2, '') undocumented,
		citizen_of, convert(varchar(12), getdate(), 112) date_stamp,
		(select 1 from candidate_udf
		where id_num = n.id_num and
		legacy = 'Y'
		) legacy,
		case 
		when source_1 in ('XWCAP') then 1
		when source_2 in ('XWCAP') then 1
		when source_3 in ('XWCAP') then 1
		when source_4 in ('XWCAP') then 1
		when source_5 in ('XWCAP') then 1
		when source_6 in ('XWCAP') then 1
		when source_7 in ('XWCAP') then 1
		when source_8 in ('XWCAP') then 1
		when source_9 in ('XWCAP') then 1
		when source_10 in ('XWCAP') then 1
		else '' end common_applied, 
		case 
		when source_1 in ('XWAAP') then 1
		when source_2 in ('XWAAP') then 1
		when source_3 in ('XWAAP') then 1
		when source_4 in ('XWAAP') then 1
		when source_5 in ('XWAAP') then 1
		when source_6 in ('XWAAP') then 1
		when source_7 in ('XWAAP') then 1
		when source_8 in ('XWAAP') then 1
		when source_9 in ('XWAAP') then 1
		when source_10 in ('XWAAP') then 1
		else '' end regular_applied		
		from name_master n, candidacy cd, candidate c, biograph_master b
		where
		n.id_num = cd.id_num and
		n.id_num = c.id_num and
		n.id_num = b.id_num and
		yr_cde = ? and
		trm_cde = ? and
		isnull(load_p_f, '') <> 'p' and
		isnull(dept_cde, '') <> 'GAP' and
		isnull(name_sts, '') <> 'D' /* and
		right(stage, 3) >= 100 */ and
		1 = case 
		when source_1 in ('XWCAP','XAWCI') then 1
		when source_2 in ('XWCAP','XAWCI') then 1
		when source_3 in ('XWCAP','XAWCI') then 1
		when source_4 in ('XWCAP','XAWCI') then 1
		when source_5 in ('XWCAP','XAWCI') then 1
		when source_6 in ('XWCAP','XAWCI') then 1
		when source_7 in ('XWCAP','XAWCI') then 1
		when source_8 in ('XWCAP','XAWCI') then 1
		when source_9 in ('XWCAP','XAWCI') then 1
		when source_10 in ('XWCAP','XAWCI') then 1
		else '' end
			});
	$sth->execute ($q->param('year'), $q->param('term'));
	while (my $contact_ref = $sth->fetchrow_hashref ()){
		next if $contact_ref->{regular_applied};
		if ($contact_ref->{undocumented} eq 'U'){ #  || $contact_ref->{citizen_of} eq 'CA'
			if ($contact_ref->{type} eq 'I'){
				$contact_ref->{type} = 'F'
			} elsif ($contact_ref->{type} eq 'K'){
				$contact_ref->{type} = 'R'
			} elsif ($contact_ref->{type} eq 'V'){
				$contact_ref->{type} = 'X'
			} elsif ($contact_ref->{type} eq 'J'){
				$contact_ref->{type} = 'T'
			}
		}
		if ($contact_ref->{type} =~ /[JKV]/){
			$contact_ref->{type} = 'INT';
		}
		$inq{$contact_ref->{type}}++; 
		$lead{$contact_ref->{type}}++ if $contact_ref->{stage} >= 160 || $contact_ref->{legacy};
		next if $contact_ref->{stage} < 400;

		unless ($contact_ref->{type}){
			main::printer("$contact_ref->{first_name} $contact_ref->{last_name} needs a type", 'output');
			next;
		}
		# push @archive, "$contact_ref->{id_num}\t$contact_ref->{first_name}\t$contact_ref->{last_name}\t$contact_ref->{yr_cde}\t$contact_ref->{trm_cde}\t$contact_ref->{stage}\t$contact_ref->{type}\n";
		unless ($contact_ref->{load_p_f}){
			main::printer("$contact_ref->{first_name} $contact_ref->{last_name} needs the full/part field completed", 'output');
		}
		if ($contact_ref->{common_applied}){
			if ($contact_ref->{stage} >= 400){ 
			#	if ($contact_ref->{stage} =~ /480|680|780/){
			#		$defapply{$contact_ref->{type}}++; 
			#	} else {
					$apply{$contact_ref->{type}}++; 
			#	}
			}
			if ($contact_ref->{stage} >= 600){ 
			#	if ($contact_ref->{stage} =~ /680|780/){
			#		$defadmit{$contact_ref->{type}}++; 
			#	} else {
					$admit{$contact_ref->{type}}++; 
			#	}
			}

			if ($contact_ref->{stage} =~ /590/){
				$deny{$contact_ref->{type}}++; 
			}

			if ($contact_ref->{stage} =~ /490/){
				$withdrawn{$contact_ref->{type}}++; 
			}

			if ($contact_ref->{stage} =~ /690/){
				$withdrawn{$contact_ref->{type}}++; 
			} 

			if ($contact_ref->{stage} >= 700){ 
			#	if ($contact_ref->{stage} =~ /780/){
			#		$defdeposit{$contact_ref->{type}}++; 
			#	} else {
					$deposit{$contact_ref->{type}}++; 
			#	}
			}
			if ($contact_ref->{stage} =~ /790/){
				$cancel{$contact_ref->{type}}++; 
			} 
		}
	}

	local $^W; # turn off -w warming

	#  push @build, $q->param('year'), $q->param('term'), "\n";

	push @build, "\nCommon App\nFirst Year Student\n" .
	"	$inq{F} Total Inquiries\n" .
	"	$lead{F} Lead\n" .
	"	$apply{F} Applied\n" .
	"	$admit{F} Admitted\n" .
	"	$deny{F} Denied\n" .
	"	$withdrawn{F} Withdrawn\n" .
	"	$deposit{F} Deposit\n" .
	"	$cancel{F} Cancel\n";	
	
	push @build, "Transfer\n" .
	"	$inq{T} Total Inquiries\n" .
	"	$lead{T} Lead\n" .
	"	$apply{T} Applied\n" .
	"	$admit{T} Admitted\n" .
	"	$deny{T} Denied\n" .
	"	$withdrawn{T} Withdrawn\n" .
	"	$deposit{T} Deposit\n" .
	"	$cancel{T} Cancel\n";	

	push @build, "Readmit\n" .
	"	$inq{R} Total Inquiries\n" .
	"	$lead{R} Lead\n" .
	"	$apply{R} Applied\n" .
	"	$admit{R} Admitted\n" .
	"	$deny{R} Denied\n" .
	"	$withdrawn{R} Withdrawn\n" .
	"	$deposit{R} Deposit\n" .
	"	$cancel{R} Cancel\n";	


	$inq = '';
	$lead = '';
	$apply = '';
	$admit = '';
	$deny = '';
	$withdraw = '';
	$deposit = '';
	$cancel = '';
	@criteria = qw/F T R/;
	
		foreach my $key (@criteria){
			$inq += $inq{$key};
			$lead += $lead{$key};
			$apply += $apply{$key};
			$admit += $admit{$key};
			$deny += $deny{$key};
			$withdraw += $withdrawn{$key};
			$deposit += $deposit{$key};
			$cancel += $cancel{$key};
		}
	
	push @build, "\nSub-Total\n" .
	"	$inq Inquiry\n" .
	"	$lead Lead\n" .
	"	$apply Apply\n" .
	"	$admit Admit\n" .
	"	$deny Deny\n" .
	"	$withdraw Withdraw\n" .
	"	$deposit Deposit\n" .
	"	$cancel Cancel\n\n";
	
	push @build, "International First Year\n" .
	"	$inq{I} Total Inquiries\n" .
	"	$lead{I} Lead\n" .
	"	$apply{I} Applied\n" .
	"	$admit{I} Admitted\n" .
	"	$deny{I} Denied\n" .
	"	$withdrawn{I} Withdrawn\n" .
	"	$deposit{I} Deposit\n" .
	"	$cancel{I} Cancel\n\n";	

	push @build, "International\n" .
	"	$inq{INT} Total Inquiries\n" .
	"	$lead{INT} Lead\n" .
	"	$apply{INT} Applied\n" .
	"	$admit{INT} Admitted\n" .
	"	$deny{INT} Denied\n" .
	"	$withdrawn{INT} Withdrawn\n" .
	"	$deposit{INT} Deposit\n" .
	"	$cancel{INT} Cancel\n";	

		$inq += $inq{I};
		$lead += $lead{I};
		$apply += $apply{I};
		$admit += $admit{I};
		$deny += $deny{I};
		$withdraw += $withdrawn{I};
		$deposit += $deposit{I};
		$cancel += $cancel{I};

		$inq += $inq{INT};
		$lead += $lead{INT};
		$apply += $apply{INT};
		$admit += $admit{INT};
		$deny += $deny{INT};
		$withdraw += $withdrawn{INT};
		$deposit += $deposit{INT};
		$cancel += $cancel{INT};
	
	$netdeposit = ($deposit - $cancel);
	push @build, "\nTotal\n" .
	"	$inq Inquiry\n" .
	"	$lead Lead\n" .
	"	$apply Apply\n" .
	"	$admit Admit\n" .
	"	$deny Deny\n" .
	"	$withdraw Withdraw\n" .
	"	$deposit Deposit\n" .
	"	$cancel Cancel\n" .
	"	$netdeposit Net Deposit\n\n";
	foreach (@build){
		s/\n/<br>/g;
		s/\t/&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;/g;
	}

	unless (open(OUT,">/home/amosmk/share/Enrollment/report_archive/$date_.txt")){
		main::printer('not working');
	}
	print OUT @archive; 
	close (OUT);
	main::printer ('', 'output', @build);

}

sub report_dashboard {
	push @{$global{tpl}{body}},
		$q->popup_menu(-name=>'year', -value=>[2010 .. 2015]), 
		$q->popup_menu(-name=>'term', -value=>['FA','SP','MA','SU']), 
		$q->submit(-name=>'report', -value=>'Run Report');
		
}

sub gc_navigator {
	open(OUT,">/home/amosmk/share/Summer Enrollment/14_fa_navigator_tracking_spreadsheet.txt");
	open(OUT2,">/home/amosmk/share/Summer Enrollment/14_fa_navigator_needed_health_or_course_items.txt");

	# my $year = '2012';

	my $sth = $global{dbh_jenz}->prepare (qq{
		select case
		when right(convert(varchar(10), getdate(), 112), 4) > '0910' then year(getdate()) + 1
		else year(getdate()) end fa_current_acad_year,
		case
		when right(convert(varchar(10), getdate(), 112), 4) <= '0115' then year(getdate())
		else year(getdate()) + 1 end sp_current_acad_year,
		case
		when right(convert(varchar(10), getdate(), 112), 4) <= '0501' then year(getdate())
		else year(getdate()) + 1 end ma_current_acad_year,
		case
		when right(convert(varchar(10), getdate(), 112), 4) <= '0528' then year(getdate())
		else year(getdate()) + 1 end su_current_acad_year
			});
	$sth->execute ();
	my $dates_ref = $sth->fetchrow_hashref ();
#	my $scholarship_includeded;
#	if ($dates_ref->{date_without_year} gt '1115' && $dates_ref->{date_without_year} lt '0906'){
#		$scholarship_includeded = 'fa'; # current or nothing;
#	}

	my (%type, %term, %fullpart, %hstype, %vehicle);
	$type{FF} = 'first-year';
	$type{TR} = 'transfer';
	$term{FA} = 'fall';
	$term{SP} = 'spring';
	$term{MA} = 'May-Term';
	$term{SU} = 'summer';
	$fullpart{F} = 'Full Time enrollment';
	$fullpart{P} = 'Part Time enrollment';
	$fullpart{'P1-5'} = 'Part Time 1-5 Hours';
	$fullpart{'P6-11'} = 'Part Time 6-11 Hours';
	$hstype{F} = 'Final';
	$hstype{O} = 'Official';
	$hstype{S} = 'Self-reported';
	$hstype{SP} = 'Partial';
	$hstype{ST} = 'Test';
	$hstype{U} = 'Unofficial';

	$vehicle{ST} = 'Student';
	$vehicle{TEMP} = 'Tempory';
	$vehicle{AD} = 'DAES';
	$vehicle{FS} = 'Fac/Staff';

	my %term_defs = ('FA','Fall','SP','Spring','MA','May','SU','Summer');

	my ($count, %header, %requirements, @headers, $select, @problems, @rows, @cover_sheet2, @cover_sheet3, @update, @calls, @column_list, $overall_update_flag);

	# Column header(underscore = space)-gsc_w_sl_enroll_docs_status.column-gsc_w_sl_enroll_docs.doc_id (number)-goldmine_column-upload(y/n)
	# * = just look in goldmine
	# ** = just look in goldmine and I'll write the lookup
	my %translation = ('key5','ID','unamelast','Last','unamefirst','First','dear','Dear','unamemid','Middle','key2','Term','department','Add_type','ubirthdate','Birthday','ufullpart','Full/Part','ugender','Gender','u_email','GC_Email','company','SSN','udeppddt','Deposit_date','uregdt','Reg_Date');

#Photo_Rcv-COMPLETED_DATE-13-UPHOTODT-date-compare
#Photo_Aprby-APPROVED_BY-13
#Photo_notes-COMMENTS-13
# reg_date-COMMENTS-Registration-c.udef_dte_5-date-compare
#SST_Rcv-COMPLETED_DATE-31-USSTFORM-date-compare
#SST_Reg_Apr-APPROVED_DATE-31
#SST_Reg_Aprby-APPROVED_BY-31
#SST_Reg_notes-COMMENTS-31
#Plug_into_Faith_Rcv-COMPLETED_DATE-16
#Plug_into_Faith_Apr-APPROVED_DATE-16
#Plug_into_Faith_Aprby-APPROVED_BY-16
#Plug_into_Faith_notes-COMMENTS-16

	my @column = qw/*first_name
*last_name
*preferred_name
*middle_name
**id_num
**status
**type
**year
**term
*addr_cde
*addr_line_1
*addr_line_2
*city
*state
*zip
**country
**deposit_date
**birthdate
**reg_date
*ssn
**fullpart
*gender
**housing
**counselor
*dorm
*roommate
**gc_email
**personal_email
PayPlan_Apr-APPROVED_DATE-Payment_Options-UPAYPLNDT-date-compare-updategm
PayPlan_Aprby-APPROVED_BY-Payment_Options
PayPlan_notes-COMMENTS-Payment_Options
Course_Interest_Rcv-COMPLETED_DATE-Advising_Questionnaire-c.udef_dte_4-date-compare-update
Course_Interest_Apr-APPROVED_DATE-Advising_Questionnaire
Course_Interest_Aprby-APPROVED_BY-Advising_Questionnaire
Course_Interest_notes-COMMENTS-Advising_Questionnaire
HS_Final_Transcript-APPROVED_DATE-Final_High_School_Transcript-UHSFTRNDT-date-compare-highschool 
Col_Final_Transcript-APPROVED_DATE-Final_College_Transcript-UCOLTYPE-varchar-compare-updategm-college
Health_Report_Self_Rcv-COMPLETED_DATE-Confidential_Health_Form-UHEALTHINF-date-compare-updategm
Health_Report_Self_Apr-APPROVED_DATE-Confidential_Health_Form-UHEALTHENV-date-compare-updategm
Health_Report_Self_Aprby-APPROVED_BY-Confidential_Health_Form
Health_Report_Self_notes-COMMENTS-Confidential_Health_Form
Measles_Rcv-COMPLETED_DATE-Measles_Record_Form-UHLTHMEAS-date-compare-updategm
Measles_Apr-APPROVED_DATE-Measles_Record_Form-UHLTHMEAA-date-compare-updategm
Measles_Aprby-APPROVED_BY-Measles_Record_Form
Measles_notes-COMMENTS-Measles_Record_Form
Meningitis_Rcv-COMPLETED_DATE-Meningitis_Letter-UHLTHMENS-date-compare-updategm
Meningitis_Apr-APPROVED_DATE-Meningitis_Letter-UHLTHMENA-date-compare-updategm
Meningitis_Aprby-APPROVED_BY-Meningitis_Letter
Meningitis_notes-COMMENTS-Meningitis_Letter
Health_Ins_Rcv-COMPLETED_DATE-Proof_of_Health_Insurance-UHEALTHINS-date-compare-updategm
Health_Ins_Apr-APPROVED_DATE-Proof_of_Health_Insurance-UHEALTHINA-date-compare-updategm
Health_Ins_Aprby-APPROVED_BY-Proof_of_Health_Insurance
Health_Ins_notes-COMMENTS-Proof_of_Health_Insurance
Health_Ins_Waived_Rcv-COMPLETED_DATE-Health_Insurance_Annual_Waiver-UHEALTHINS-date
Health_Ins_Waived_Apr-APPROVED_DATE-Health_Insurance_Annual_Waiver-UHEALTHINA-date
Health_Ins_Waived_Aprby-APPROVED_BY-Health_Insurance_Annual_Waiver
Health_Ins_Waived_notes-COMMENTS-Health_Insurance_Annual_Waiver
Health_Ins_Spring_Waived_Rcv-COMPLETED_DATE-Health_Insurance_Waiver-UHEALTHINS-date
Health_Ins_Spring_Waived_Apr-APPROVED_DATE-Health_Insurance_Waiver-UHEALTHINA-date
Health_Ins_Spring_Waived_Aprby-APPROVED_BY-Health_Insurance_Waiver
Health_Ins_Spring_Waived_notes-COMMENTS-Health_Insurance_Waiver
Summer_Reg_Rcv-COMPLETED_DATE-1-c.udef_dte_5-date-compare
Summer_Reg_Apr-APPROVED_DATE-1
Summer_Reg_Aprby-APPROVED_BY-1
Summer_Reg_notes-COMMENTS-1
Housing_Rcv-COMPLETED_DATE-Admission_Response_Form-c.udef_dte_6-date-compare
Housing_Reg_Apr-APPROVED_DATE-Admission_Response_Form
Housing_Reg_Aprby-APPROVED_BY-Admission_Response_Form
Housing_Reg_notes-COMMENTS-Admission_Response_Form
more_Meal
more_Vehicle_reg
more_Comm_verify
more_college_hs_info
more_ap_tests
/;

	my ($string);
	push @update, "accountno\t";
	foreach (@column){
		my $name = $_;
		if ($name =~ /^\*/){
			unless ($name =~ s/^\*\*// || $name =~ /2_/){
				$name =~ s/^\*//;
				$string .= "$name, ";
			}
			if ($name eq 'country'){
				push @cover_sheet2, "$name\t2_Addr_type\t2_Address1\t2_Address2\t2_City\t2_State\t2_Zip\t2_Country\t";
				push @cover_sheet3, "$name\t2_Addr_type\t2_Address1\t2_Address2\t2_City\t2_State\t2_Zip\t2_Country\t";
				next;
			}
			if ($translation{$name}){
				push @cover_sheet2, "$translation{$name}\t";
				push @cover_sheet3, "$translation{$name}\t";
			} else {
				push @cover_sheet2, "$name\t";
				push @cover_sheet3, "$name\t";
			}
		} elsif ($name =~ s/^more_college_hs_info//){
		} elsif ($name =~ s/^more_ap_tests//){
		} elsif ($name =~ s/^more_//){
			push @cover_sheet2, "$name\t";
			push @cover_sheet3, "$name\t";
			push @update, "$name\t";
		} else {
			my @split = split(/-/, $name);
			push @cover_sheet2, "$split[0]\t";
			push @cover_sheet3, "$split[0]\t";
			if ($split[6] && $split[6] =~ /updategm/){
				push @update, "$split[3]\t";
			}
		}	
	}
	$cover_sheet2[-1] =~ s/\t/\n/;
	$cover_sheet3[-1] =~ s/\t/\n/;
	$update[-1] =~ s/\t/\n/;
	my %counselor_email;
	$sth = $global{dbh_jenz}->prepare (qq{
		select n.id_num, $string isnull(first_name, '') + ' ' + isnull(last_name, '') contact,
		right(stage, 3) stage, load_p_f fullpart, yr_cde year, trm_cde term, housing_cde,
		addr_line_1 address1, addr_line_2 address2, addr_line_3 address3, city, state, zip, dbo.gsc_cm_tel_format_sf(phone, '(xxx)xxx-xxxx') phone, dbo.gsc_cm_tel_format_sf(n.mobile_phone, '(xxx)xxx-xxxx') cell,
		( 	select table_desc from table_detail
			where
			table_value = country and
			column_name = 'country' 
		) country,
		(	select top 1 county_name from gsc_citycounty
			where
			county = a.county
		) county,
		(	select 1 from candidate
			where
			id_num = n.id_num and
			isnull(udef_dte_5, '') <> '' and
			convert(varchar(12), udef_dte_5, 112) <> '20140401' and
			(	convert(varchar(12), udef_dte_5, 112) = '20141231' or
				DATEDIFF(DAY, getdate(), udef_dte_5) < 7
			)
		) reg_date_ready,
		(select top 1 convert(varchar(12), hist_stage_dte, 101) from stage_history_tran
			where
			id_num = n.id_num and
			hist_stage = 'A700' and
			yr_cde = cd.yr_cde and
			trm_cde = cd.trm_cde
		) deposit_date,
		convert(varchar(12), c.udef_dte_5, 101) reg_date,
		/* (select top 1 completion_dte_dte from requirements
		where
		id_num = n.id_num and
		trm_cde = cd.trm_cde and
		yr_cde = cd.yr_cde and
		req_cde = 'REGDT' and
		completion_sts = 'Y' ) reg_date, */ convert(varchar(12), getdate(), 101) as date,
		convert(varchar(12), getdate(), 1) cdate,
		convert(varchar(12), birth_dte, 101) as birthdate,
		convert(varchar(12), c.udef_dte_5, 101) as reg_date,
		/* (select top 1 hist_stage_dte from stage_history_tran
		where
		id_num = n.id_num and
		right(hist_stage, 3) = '720' and
		yr_cde = cd.yr_cde and
		trm_cde = cd.trm_cde
		) reg_date, */
		(select table_desc from table_detail
			where
			column_name = 'resid_commuter_sts' and
			table_value = housing_cde
		) housing, 
		(select top 1 addr_line_1
		from address_master
		where id_num = n.id_num and
		addr_cde in ('*EML') and
		addr_line_1 like '%goshen.edu'
		) gc_email,
		(select table_desc from table_detail
			where
			column_name = 'resid_commuter_sts' and
			table_value = housing_cde
		) housing, 
		(select top 1 addr_line_1
		from address_master
		where id_num = n.id_num and
		addr_cde in ('*EML','PPEM','EML2') and
		isnull(addr_line_1, '') not like '%goshen.edu'
		order by case when addr_cde = '*EML' then 1
		when addr_cde = 'PPEM' then 2
		else 3
		end
		) personal_email,
		(select top 1 candidacy_typ_desc from candidacy_type_def where candidacy_type = cd.candidacy_type) type,
		(select top 1 rtrim(stage_desc) + ' ('+substring(stage, 2, 3)+')' from stage_config
		where
		substring(stage, 2, 3) = right(cd.stage, 3)
		) status,
		(select top 1 table_desc from table_detail
			where column_name = 'resid_commuter_sts' and
			table_value = housing_cde
		) housing,
		(select counselor_title from counselor_responsi
		where
		counselor_initials = c.counselor_initials
		) counselor,
		counselor_initials
		-- from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = case when isnull(n.current_address, '') = '' then '*LHP' when current_address in ('PLCL','*LHP') then current_address else '*LHP' end,
		from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = '*LHP',
		biograph_master b 
		left join candidacy cd on b.id_num = cd.id_num and CUR_CANDIDACY = 'Y'
		left join candidate c on cd.id_num = c.id_num
		left join candidate_udf u on c.id_num = u.id_num
		where
		n.id_num = b.id_num and
		(yr_cde = '2014' and trm_cde in ('FA') or
		yr_cde = '2013' and trm_cde in ('SU','MA')) and
		--yr_cde = '2014' and trm_cde in ('SP','SU','MA') and
		right(stage, 3) >= '700' and
		div_cde <> 'GR' and
		isnull(prog_cde, '') <> '460' and
		candidacy_type in ('F','I','P','K','V','J','P','R','T','X','G','N') and
		isnull(dept_cde, '') <> 'GAP' and
		isnull(name_sts, '') <> 'D' and
		isnull(prog_cde, '') not in ('46','460')
		-- and n.id_num = 732778
		order by last_name, first_name
			});
	$sth->execute ();
	while (my $contact_ref = $sth->fetchrow_hashref ()){
		my ($withdrawan, $flag);
		# print "$contact_ref->{contact}\n";
		my @cover_sheet;
		if ($contact_ref->{stage} =~ /.9./){
			$contact_ref->{unamefirst} .= ' CANCELED';
			$contact_ref->{contact} .= ' CANCELED';
			$withdrawan++;
		} elsif ($contact_ref->{stage} =~ /.8./){
			$contact_ref->{unamefirst} .= ' DEFERRED';
			$contact_ref->{contact} .= ' DEFERRED';
			$withdrawan++;
		}
		my (%ap, $ap_counter, @problem_list, $update_flag, @update_store, $not_logged_in_oracle, $logged_in_oracle);
		push my @name_id, "\n$contact_ref->{id_num} - $contact_ref->{contact} ($contact_ref->{year} $contact_ref->{term}) - $contact_ref->{counselor}\n";
		my @initiate_reminder;
		local $^W; # turn off strict flag
		foreach (@column){
			my $name = $_;
			if ($name =~ /^\*/){
				$name =~ s/^\**//;
				if ($name eq 'ufullpart'){
					push @cover_sheet, "$fullpart{$contact_ref->{$name}}\t";
				} elsif ($name eq 'company'){
					$contact_ref->{$name} =~ s/(...)(..)(....)/$1-$2-$3/;
					push @cover_sheet, "$contact_ref->{$name}\t";
				} else {
					if ($contact_ref->{$name}){
						push @cover_sheet, "$contact_ref->{$name}\t";
					} else {
						push @cover_sheet, "\t";
					}
					if ($name eq 'country'){
						# print "running\n";
						my $sth = $global{dbh_jenz}->prepare (qq{
							select addr_cde, addr_line_1 address1, addr_line_2 address2, addr_line_3 address3, city, state, zip,
							( 	select table_desc from table_detail
								where
								table_value = country and
								column_name = 'country' 
							) country
							-- from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = case when isnull(n.current_address, '') = '' then 'PLCL' when current_address in ('*LHP') then 'PLCL' when current_address in ('PLCL') then '*LHP' else 'null' end
							from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = 'PLCL'
							where
							n.id_num = ?
							-- and n.id_num = 730696
								});
						$sth->execute ($contact_ref->{id_num});
						my $address2_ref = $sth->fetchrow_hashref ();
						push @cover_sheet, "$address2_ref->{addr_cde}\t$address2_ref->{address1}\t$address2_ref->{address2}\t$address2_ref->{city}\t$address2_ref->{state}\t$address2_ref->{zip}\t$address2_ref->{country}\t";
					}
				}
			} elsif ($name =~ /more_college_hs_info/){
				$name =~ s/^more_//;
				my @info = ($contact_ref->{id_num}, $contact_ref->{load_p_f});
				my $sth = $global{dbh_jenz}->prepare (qq{
					select isnull(last_name, '')+isnull(first_name, '') name, a.udef_2a_1 type from name_master n, ad_org_tracking a
					where
					a.id_num = ? and
					n.id_num = org_id__ad and
					org_type_ad_ = 'HS' and
					last_high_school = 'Y'
						});
				$sth->execute ($contact_ref->{id_num});
				my $hs_ref = $sth->fetchrow_hashref ();
				push @info, $hs_ref->{name};

				my ($ccount, $hours);
				my $notfinal;
				$sth = $global{dbh_jenz}->prepare (qq{
					select top 5 
					case
					when udef_2a_1 = 'F' then 'Final'
					when udef_2a_1 = 'G' then 'On file with Registrar'
					when udef_2a_1 = 'N' then 'Not needed'
					when udef_2a_1 = 'O' then 'Official'
					else 'Self-reported' end type,
					(select isnull(last_name, '')+isnull(first_name, '') from name_master
					where
					id_num = org_id__ad
					) name, udef_3a_1 total_hrs
					from ad_org_tracking
					where
					id_num = ? and
					org_type_ad_ = 'CL'
						});
				$sth->execute ($contact_ref->{id_num});
				while (my $college_hs_ref = $sth->fetchrow_hashref ()){
					$ccount++;
					$hours += $college_hs_ref->{total_hrs};
					push @info, "$college_hs_ref->{name} ($college_hs_ref->{type})";
					$notfinal++ unless $college_hs_ref->{type} =~ /Final|On file with Registrar|Not needed/;
				}
				for (my $i = $ccount; $i < 5; $i++){
					push @info, "";
				}
				push @info, $hours;
				push @info, 'jlshown';
				push @info, $contact_ref->{cdate};
				push @info, $contact_ref->{housing};

				$sth = $global{dbh_jenz}->prepare (qq{
					select ID_NUM from gsc_w_sl_enroll_info
					where
					ID_NUM = ?
						});
				$sth->execute ($contact_ref->{id_num});
				if (my $o_college_hs_ref = $sth->fetchrow_hashref ()){
#					main::printer('working');
					my $sth = $global{dbh_jenz}->prepare (qq{
						update gsc_w_sl_enroll_info set	ID_NUM = ?, INTENDED_CREDIT_HRS = ?, HIGH_SCHOOL_TRANSCRIPT = ?, COLLEGE_TRANSCRIPT_1 = ?, 
							COLLEGE_TRANSCRIPT_2 = ?, COLLEGE_TRANSCRIPT_3 = ?, COLLEGE_TRANSCRIPT_4 = ?, COLLEGE_TRANSCRIPT_5 = ?,
							TOTAL_COLLEGE_HRS = ?, MOD_USER = ?, MOD_DATE = ?, HOUSING = ?
						where
						ID_NUM = $contact_ref->{id_num}
							});
					$sth->execute (@info);
				} else {
#					foreach (@$college_hs_ref){
#						print "$_\n";
#					}
					my $sth = $global{dbh_jenz}->prepare (qq{
					insert into gsc_w_sl_enroll_info 
					(
						ID_NUM, INTENDED_CREDIT_HRS, HIGH_SCHOOL_TRANSCRIPT, COLLEGE_TRANSCRIPT_1, 
						COLLEGE_TRANSCRIPT_2, COLLEGE_TRANSCRIPT_3, COLLEGE_TRANSCRIPT_4, 
						COLLEGE_TRANSCRIPT_5, TOTAL_COLLEGE_HRS, MOD_USER, MOD_DATE, HOUSING
					)
					values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
						});
					$sth->execute (@info);
				}
				if ($ccount && !$notfinal){
					my $doc_year = $contact_ref->{year}; 
					my $doc_term = $contact_ref->{term};
					my @split = split(/-/, $name);
					$split[2] =~ s/_/ /g;
	#				print "$contact_ref->{key5}, $doc_term.'%', $term_defs{$doc_term} $doc_year, @split[2].'%'\n";
					my $sth = $global{dbh_jenz}->prepare (qq{
						select distinct a.doc_id, a.doc_title, option_desc
						from gsc_w_sl_enroll_docs a, gsc_w_sl_enroll_access b,
						gsc_w_sl_enroll_option c, gsc_w_sl_enroll_docs_status d 
						where a.doc_id = b.doc_id
						  and a.doc_id = d.doc_id 
						  and d.id_num = ?
						  and b.option_id = c.option_id
						  and c.option_value like ?
						  and a.act_inact_sts = 'a'
						  and option_desc = ?
						  and a.doc_title like ?
							});
					$sth->execute ($contact_ref->{id_num}, $doc_term.'%', "$term_defs{$doc_term} $doc_year", 'Final College Transcript%');
					my $doc_id_ref = $sth->fetchrow_hashref (); # grab the correct doc_id
					$doc_id_ref->{doc_id} = $split[2] if $split[2] =~ /[\d]/; # if it's a stagnant number
					$sth = $global{dbh_jenz}->prepare (qq{
						select id_num, replace(COMPLETED_DATE, char(10), '') date from gsc_w_sl_enroll_docs_status
						where
						id_num = ? and
						doc_id = ?
							});
					$sth->execute ($contact_ref->{id_num}, $doc_id_ref->{doc_id});
					if (my $final_ref = $sth->fetchrow_hashref ()){
						push @problem_list, "All colleges are final and the final checkmark should be checked in gcnavigator - $contact_ref->{counselor}\n" unless $final_ref->{date};
					}
				}
			} elsif ($name =~ /more_ap_tests/){
#				$name =~ s/^more_//;
#				my ($ap_score_ref, $o_college_hs_ref);
#				my $sth = $dbh_common_2->prepare (qq{
#					select key5, 
#					case
#					when UPLACETS like '%French%' then 'Y'
#					else 'N' end,
#					case
#					when UPLACETS like '%Spanish%' then 'Y'
#					else 'N' end,
#					case
#					when UPLACETS like '%Math%' then 'Y'
#					else 'N' end
#					from contact1, contact2
#					where   
#					contact1.accountno = contact2.accountno and
#					contact1.accountno  = ?
#						});
#				$sth->execute ($contact_ref->{accountno});
#				if (my $ap_score_ref = $sth->fetchrow_arrayref ()){
#					my $sth = $dbh_GC7->prepare (qq{
#						select ID_NUM from gsc_w_sl_enroll_info
#						where
#						ID_NUM = ?
#							});
#					$sth->execute ($contact_ref->{key5});
#					if (my $o_college_hs_ref = $sth->fetchrow_hashref ()){
#						my $sth = $dbh_GC7->prepare (qq{
#							update gsc_w_sl_enroll_info set	ID_NUM = ?, french_placement_test = ?, spanish_placement_test = ?, math_placement_test = ? 
#							where
#							ID_NUM = @$ap_score_ref[0]
#								});
#						$sth->execute (@$ap_score_ref);
#					} else {
#						my $sth = $dbh_GC7->prepare (qq{
#						insert into gsc_w_sl_enroll_info 
#						(
#							ID_NUM, french_placement_test, spanish_placement_test, math_placement_test
#						)
#						values (?, ?, ?, ?)
#							});
#						$sth->execute (@$ap_score_ref);
#					}
#				}
			} elsif ($name =~ /more_Comm_verify/){
				$name =~ s/^more_//;
				my $sth = $global{dbh_jenz}->prepare (qq{
					select id_num from GSC_RE_SIF_INFORMATION
					where
					ID_NUM = ?
						});
				$sth->execute ($contact_ref->{key5});
				if (my $oracle_ref = $sth->fetchrow_hashref ()){
					$update_flag++ if $contact_ref->{$name} ne 'Complete';
					push @cover_sheet, "Complete\t";
					push @update_store, "Complete\t";					
				} else {
					$update_flag++ if $contact_ref->{$name};
					push @cover_sheet, "\t";
					push @update_store, "\t";
				}
			} elsif ($name =~ /more_Meal/){
				$name =~ s/^more_//;
				my $sth = $global{dbh_jenz}->prepare (qq{
					select c.id_num,
					       ( select last_name+', '+first_name from name_master where id_num = c.id_num) name,
					       resid_commuter_sts dorm_student,
					       meal_plan jenz_meal_plan,
					       dbo.gsc_cm_table_detail_sf(meal_plan,'meal_plan', default, default) meal_plan_desc
					  from candidacy c left join stud_sess_assign s on c.id_num = s.id_num
					 where c.id_num = ? and
					(yr_cde = '2014' and trm_cde = 'FA' or
					yr_cde = '2013' and trm_cde = 'SP')
					   and rtrim(sess_cde) = c.trm_cde+c.yr_cde
					   and dbo.gsc_re_prereg_student_sf(c.id_num,c.trm_cde+c.yr_cde,'y') = 'y'
						});
				$sth->execute ($contact_ref->{id_num});
				if (my $oracle_ref = $sth->fetchrow_hashref ()){
					$oracle_ref->{meal_plan_desc} =~ s/ - .*//;
					$update_flag++ if $contact_ref->{$name} ne $oracle_ref->{meal_plan_desc};
					push @cover_sheet, "$oracle_ref->{meal_plan_desc}\t";
					push @update_store, "$oracle_ref->{meal_plan_desc}\t";
				} else {
					$update_flag++ if $contact_ref->{$name};
					push @cover_sheet, "\t";
					push @update_store, "\t";
				}
			} elsif ($name =~ /more_Vehicle_reg/){
				$name =~ s/^more_//;
				my $sth = $global{dbh_jenz}->prepare (qq{
					select rtrim(sa_vp_cde) sa_vp_cde, vp_sts
					from cm_sa_vehcl_reg
					where 
					vp_sts = 'a' and 
					exists (
						select null
					        from candidacy
					        where cm_sa_vehcl_reg.id_num_vp_holder = id_num and
						id_num = ? and
					        trm_cde+yr_cde = (select top 1 sess_cde from gsc_reg_yr_trm_cde_v where program = 's' and code = 'fu')
					)
						});
				$sth->execute ($contact_ref->{id_num});
				if (my $oracle_ref = $sth->fetchrow_hashref ()){
					if ($vehicle{$oracle_ref->{sa_vp_cde}}){
						$update_flag++ if $contact_ref->{$name} ne "$vehicle{$oracle_ref->{sa_vp_cde}}";
						push @cover_sheet, "$vehicle{$oracle_ref->{sa_vp_cde}}\t";
						push @update_store, "$vehicle{$oracle_ref->{sa_vp_cde}}\t";
					} else {
						$update_flag++ if $contact_ref->{$name} ne "$oracle_ref->{sa_vp_cde}";
						push @cover_sheet, "$oracle_ref->{sa_vp_cde}\t";
						push @update_store, "$oracle_ref->{sa_vp_cde}\t";

					}
				} else {
					$update_flag++ if $contact_ref->{$name};
					push @cover_sheet, "\t";					
					push @update_store, "\t";
				}
			} else {
				# next unless $name =~ /^Course_Interest_Rcv/;
				# print "$name\n";
				# headername = 0
				# oracle header name = 1
				# doc_id_name = 2
				# gm column = 3
				# column format = 4
				# directives = 5
				my $doc_year = $contact_ref->{year}; 
				my $doc_term = $contact_ref->{term};
				my @split = split(/-/, $name);
				$split[2] =~ s/_/ /g;
				# print "$contact_ref->{key5}, $doc_term.'%', $term_defs{$doc_term} $doc_year, $split[0].'%'\n";
				my $sth = $global{dbh_jenz}->prepare (qq{
					select distinct a.doc_id, a.doc_title, option_desc
					from gsc_w_sl_enroll_docs a, gsc_w_sl_enroll_access b,
					gsc_w_sl_enroll_option c, gsc_w_sl_enroll_docs_status d 
					where a.doc_id = b.doc_id
					  and a.doc_id = d.doc_id 
					  and d.id_num = ?
					  and b.option_id = c.option_id
					  and c.option_value like ?
					  and a.act_inact_sts = 'a'
					  and option_desc = ?
					  and a.doc_title like ?
						});
				$sth->execute ($contact_ref->{id_num}, $doc_term.'%', "$term_defs{$doc_term} $doc_year", $split[2].'%');
				my $doc_id_ref = $sth->fetchrow_hashref (); # grab the correct doc_id
				$doc_id_ref->{doc_id} = $split[2] if $split[2] =~ /[\d]/; # if it's a stagnant number
				my ($oracle_ref);
				$sth = $global{dbh_jenz}->prepare (qq{
					select id_num, replace($split[1], char(10), '') $split[1] from gsc_w_sl_enroll_docs_status
					where
					id_num = ? and
					doc_id = ?
						});
				$sth->execute ($contact_ref->{id_num}, $doc_id_ref->{doc_id});
				if ($oracle_ref = $sth->fetchrow_hashref ()){
					$oracle_ref->{$split[1]} =~ s/\r//g;
					$oracle_ref->{$split[1]} =~ s/^(.{25}).*/$1.../;
					if ($split[0] eq 'summer_reg_rcv'){
						push @cover_sheet, "$contact_ref->{$split[3]}\t";					
					} else {
						push @cover_sheet, "$oracle_ref->{$split[1]}\t";					
					}
					if ($split[0] eq 'Course_Interest_Rcv'){
						$flag .= 'A' if $oracle_ref->{$split[1]};
					} elsif ($split[0] =~ /Health_Report_Self_Apr|Measles_Apr/){
						$flag .= 'B' if $oracle_ref->{$split[1]};
					}
	
					@initiate_reminder = ();
					$logged_in_oracle++;
				} else {
					push @initiate_reminder, "!!!! not initiated in GC Navigator - $contact_ref->{counselor}\n" unless $not_logged_in_oracle || $logged_in_oracle;
					$not_logged_in_oracle++;
					push @cover_sheet, "\t";
				}
				if ($split[7] eq 'college'){
					my $col_type;
					$sth = $global{dbh_jenz}->prepare (qq{
						select top 6 
						case
						when udef_2a_1 = 'F' then 'Final'
						when udef_2a_1 = 'G' then 'On file with Registrar'
						when udef_2a_1 = 'N' then 'Not needed'
						when udef_2a_1 = 'O' then 'Official'
						else 'Self-reported' end type,
						udef_2a_1,
						(select isnull(last_name, '')+isnull(first_name, '') from name_master
						where
						id_num = org_id__ad
						) name, udef_3a_1 total_hrs
						from ad_org_tracking
						where
						id_num = ? and
						org_type_ad_ = 'CL'
							});
					$sth->execute ($contact_ref->{id_num});
					while (my $college_hs_ref = $sth->fetchrow_hashref ()){
						if (($college_hs_ref->{udef_2a_1} && $college_hs_ref->{udef_2a_1} !~ /[FGNO]/ || !$college_hs_ref->{udef_2a_1})){
							$col_type = 'needed';
							last;
						} elsif ($college_hs_ref->{udef_2a_1} =~ /^O/){
							$col_type = 'official';
						} elsif ($college_hs_ref->{udef_2a_1} =~ /^F/ && $col_type ne 'official'){
							$col_type = 'final';
						}
					}
					if (!$oracle_ref->{$split[1]} && $col_type eq 'final'){
						push @problem_list, "$split[0] is in Jenzabar but not in GC Navigator - $contact_ref->{counselor}\n" if $split[5] eq 'compare' && $oracle_ref->{id_num};
					} elsif ($oracle_ref->{$split[1]} && $col_type ne 'final'){
						push @problem_list, "$split[0] is in GC Navigator but not in Jenzabar - $contact_ref->{counselor}\n";
					}
#					if ($check_ref->{ucoltype} ne $col_type){
#						$update_flag++;
#					}
					push @update_store, "$col_type\t";
				} elsif ($split[6] eq 'highschool'){
					my $hs_type;
					$sth = $global{dbh_jenz}->prepare (qq{
						select top 1 
						case
						when udef_2a_1 = 'F' then 'Final'
						when udef_2a_1 = 'G' then 'On file with Registrar'
						when udef_2a_1 = 'N' then 'Not needed'
						when udef_2a_1 = 'O' then 'Official'
						else 'Self-reported' end type,
						udef_2a_1,
						(select isnull(last_name, '')+isnull(first_name, '') from name_master
						where
						id_num = org_id__ad
						) name
						from ad_org_tracking
						where
						id_num = ? and
						org_type_ad_ = 'HS' and
						last_high_school = 'Y'
							});
					$sth->execute ($contact_ref->{id_num});
					while (my $college_hs_ref = $sth->fetchrow_hashref ()){
						if ($college_hs_ref->{udef_2a_1} && $college_hs_ref->{udef_2a_1} !~ /[FGNO]/){
							$hs_type = 'needed';
							last;
						} elsif ($college_hs_ref->{udef_2a_1} =~ /^O/){
							$hs_type = 'official';
						} elsif ($college_hs_ref->{udef_2a_1} =~ /^F/ && $hs_type ne 'official'){
							$hs_type = 'final';
						}
					}
					if (!$oracle_ref->{$split[1]} && $hs_type eq 'final'){
						push @problem_list, "$split[0] is in Jenzabar but not in GC Navigator - $contact_ref->{counselor}\n" if $split[5] eq 'compare' && $oracle_ref->{id_num};
					} elsif ($oracle_ref->{$split[1]} && $hs_type ne 'final'){
						push @problem_list, "$split[0] is in GC Navigator but not in Jenzabar - $contact_ref->{counselor}\n";
					}
#					if ($check_ref->{ucoltype} ne $hs_type){
#						$update_flag++;
#					}
					push @update_store, "$hs_type\t";
				} elsif ($split[3]){
					# print "$split[3] fred\n";
					my $column;
					if ($split[4] eq 'date'){
						$column = "convert(varchar(12), $split[3], 111) compare, convert(varchar(12), $split[3], 101) display";
					} else {
						$column = $split[3];
					}
					if ($split[3] =~ /\./){
						my $sth = $global{dbh_jenz}->prepare (qq{
							select $column from candidate c, candidate_udf udf
							where
							c.id_num = udf.id_num and
							c.id_num = ? and
							isnull($split[3], '') <> ''
								});
						$sth->execute ($contact_ref->{id_num});
						if (my $check_ref = $sth->fetchrow_hashref ()){
							# print "$check_ref->{compare}\n";
							$check_ref->{compare} =~ s/\//-/g;
							if (!$oracle_ref->{$split[1]}){
								if ($split[3] eq 'upreregdt' && $check_ref->{compare} eq '2008-05-02'){ # this means that we know they want to register by phone but we don't know the exact phone reg date - this date is in Jenzabar but we don't want a reminder to put it in GC Navigator
									# no warnings
								} elsif ($split[3] eq 'c.udef_dte_6' && $contact_ref->{housing_cde} !~ /d/i){
									# no warnings
								} else {
									# push @problem_list, "$split[0] is in Jenzabar but not in gcnavigator\n" if $split[5] eq 'compare' && ($oracle_ref->{id_num} || $split[0] eq 'summer_reg_rcv');
									push @problem_list, "$split[0] is in Jenzabar but not in gcnavigator - $contact_ref->{counselor}\n" if $split[5] eq 'compare';
									# push @problem_list, "$check_ref->{compare} - $contact_ref->{uadvtime}\n" if $split[0] eq 'summer_reg_rcv';
								}
							}
						} elsif ($oracle_ref->{$split[1]}){
							push @problem_list, "$split[0] is in GC Navigator but not in Jenzabar - $contact_ref->{counselor}\n" if $split[5] eq 'compare';
	#						if ($split[0] eq 'summer_reg_rcv'){
	#							my $sth2 = $dbh_gc7->prepare (qq{
	#								select registration from gsc_w_sl_enroll_registration
	#								where
	#								id_num = ?
	#									});
	#							$sth2->execute ($contact_ref->{key5});
	#							my $oracle_reg_ref = $sth2->fetchrow_hashref ();
	#							push @problem_list, "$oracle_reg_ref->{registration}\n";
	#						}
	#						$update_flag++ if $split[6] =~ /updategm/;
						}
					}
#					if ($split[6] =~ /updategm/){
#						if ($oracle_ref->{$split[1]}){
#							$oracle_ref->{$split[1]} =~ /(.*)-(..)-(..)/;
#							push @update_store, "$2/$3/$1\t";
#						} else {
#							push @update_store, "\t";
#						}
#					}
				}
			}
		}
		if ($withdrawan){
			# skip
			# my $temp = pop (@cover_sheet);
		} else {
			$cover_sheet[-1] =~ s/\t/\n/;
			push @cover_sheet2, @cover_sheet;
			unless ($flag && $flag =~ /A/ && $flag =~ /B/){ # only student who need health form or advising sheet
				unless($cover_sheet[1] =~ /DEFERRED|CANCELED/){
					push @cover_sheet3, @cover_sheet if $contact_ref->{reg_date_ready};
				}
			}
		}
 		$counselor_email{$contact_ref->{counselor_initials}} .= "$contact_ref->{id_num} $contact_ref->{contact} - No Advising Questionnaire\n" if $contact_ref->{reg_date_ready} && $flag !~ /A/;
		$counselor_email{$contact_ref->{counselor_initials}} .= "$contact_ref->{id_num} $contact_ref->{contact} - No Confidential Health Form or Measles\n" if $contact_ref->{reg_date_ready} && $flag !~ /B/;
#		if ($update_flag){
##			$count++;
##			print "$count\n";	
#			$overall_update_flag++;
#			@update_store[-1] =~ s/\t/\n/;
#			push @update, "$contact_ref->{accountno}	", @update_store;
#		}
		if ((@problem_list || @initiate_reminder) && $contact_ref->{key1} !~ /^.9/){
			push @problems, @name_id, @initiate_reminder, @problem_list;
		}
	}
	# print "@problems\n";
	if (0){
		if (@problems){
			use Net::SMTP;

			my $smtp = Net::SMTP->new('email.goshen.edu');
			$smtp->auth("telecounselor1", 'eL83-qky') or
				die ("Failed to authenticate. $!\n");

			$smtp->mail('amosmk');
			$smtp->to('admission@goshen.edu','admission@goshen.edu');

			$smtp->data();
			$smtp->datasend("From: Amos Kratzer <amosmk\@goshen.edu>\n");
			$smtp->datasend("To: Sara Bogen <admission\@goshen.edu>\n");
			$smtp->datasend("Subject: GCNavigator Snyc\n");

			$smtp->datasend("\n");
			$smtp->datasend("@problems\n");
			$smtp->dataend();
		}
	}
	my %counemail;
	$sth = $global{dbh_mailer}->prepare (qq{
		select * from user
		where
		u_counselor = 'yes'
			});
	$sth->execute ();
	while (my $coun_ref = $sth->fetchrow_hashref ()){
		# only for counselors;
		$counemail{$coun_ref->{u_ini}} = $coun_ref->{u_email};
	}

	if (0){		
		while(my($name, $value) = each(%counselor_email)){
			# print "$counemail{$name}\n";
			use Net::SMTP;

			my $smtp = Net::SMTP->new('email.goshen.edu');
			$smtp->auth("telecounselor1", 'eL83-qky') or
				die ("Failed to authenticate. $!\n");

			$smtp->mail('amosmk');
			$smtp->to($counemail{$name},'admission@goshen.edu');  

			$smtp->data();
			$smtp->datasend("From: Amos Kratzer <amosmk\@goshen.edu>\n");
			$smtp->datasend("To: $counemail{$name}, admission\@goshen.edu\n");
			$smtp->datasend("Subject: GCNavigator heads up\n");

			$smtp->datasend("\n");
			$smtp->datasend("$value\n");
			$smtp->dataend();
		}	
	}
	print OUT @cover_sheet2;
	print OUT2 @cover_sheet3;
}

sub pla_spreadsheet {
	my @ranges = qw/1540_1590 1490_1530 1440_1580 1400_1430 1360_1490 1330_1350 1290_1320 1250_1280 1210_1240 1170_1200 1130_1160 1090_1120 1050_1080 1020_1040 980_1010 940_970 900_930 860_890 820_850 770_810 720_760 670_710 620_660 560_610 510_550/;
	my %convert;
	$convert{a1540_1590} = '35';
	$convert{a1490_1530} = '34';
	$convert{a1440_1580} = '33';
	$convert{a1400_1430} = '32';
	$convert{a1360_1490} = '31';
	$convert{a1330_1350} = '30';
	$convert{a1290_1320} = '29';
	$convert{a1250_1280} = '28';
	$convert{a1210_1240} = '27';
	$convert{a1170_1200} = '26';
	$convert{a1130_1160} = '25';
	$convert{a1090_1120} = '24';
	$convert{a1050_1080} = '23';
	$convert{a1020_1040} = '22';
	$convert{a980_1010} = '21';
	$convert{a940_970} = '20';
	$convert{a900_930} = '19';
	$convert{a860_890} = '18';
	$convert{a820_850} = '17';
	$convert{a770_810} = '16';
	$convert{a720_760} = '15';
	$convert{a670_710} = '14';
	$convert{a620_660} = '13';
	$convert{a560_610} = '12';
	$convert{a510_550} = '11';


	my ($count, @literature, $counttotal, $americansabroad);
		push my @load, "ID	First	Last	Gender	Major	Act	Sat	Revised Test Score	Gpa_Weighted	Essay	Student Interview	Faculty Interview	Faculty Interview	Assessment	Total	admstatus	Status	City	State	High_school	Denomination	Ethnicity\n";
	my $sth = $global{dbh_jenz}->prepare (qq{
		select yr_cde+ ' ' + trm_cde year_term, n.id_num, first_name, last_name, gender,
		dbo.GSC_MAJOR_CDE_TRANSL_SF(prog_cde) Major1,
		(select top 1 rtrim(stage_desc) + ' ('+substring(stage, 2, 3)+')' from stage_config
		where
		substring(stage, 2, 3) = right(cd.stage, 3)
		) status,
		(select candidacy_typ_desc from candidacy_type_def where candidacy_type = cd.candidacy_type) type,
		(select cast(round (self_reported_gpa, 2,0) as decimal(10,2))
			from ad_org_tracking
			where
			id_num = n.id_num and
			last_high_school = 'Y' and
			org_type_ad_ = 'HS'	
		) hs_gpa_weighted,
		(select cast(round (gpa, 2,0) as decimal(10,2))
			from ad_org_tracking
			where
			id_num = n.id_num and
			last_high_school = 'Y' and
			org_type_ad_ = 'HS'	
		) hs_gpa,
		cast(round ( 
		(select max(tst_score) 
			from test_scores_detail
			where 
			id_num = n.id_num and 
			tst_cde = 'SAT' and
			tst_elem = 'satv' and
			exists ( select 1 from test_scores
				where
				id_num = test_scores_detail.id_num and
				self_reported = 'n'
			)
		) +
		(select max(tst_score) 
			from test_scores_detail
			where 
			id_num = n.id_num and 
			tst_cde = 'SAT' and
			tst_elem = 'satm' and
			exists ( select 1 from test_scores
				where
				id_num = test_scores_detail.id_num and
				self_reported = 'n'
			)
		),2,0) as decimal(10,0)) sat,
		(cast(round (
			((select max(tst_score)
					from test_scores_detail
					where 
					id_num = n.id_num and 
					tst_cde = 'ACT' and
					tst_elem = 'acten' and
					exists ( select 1 from test_scores
						where
						id_num = test_scores_detail.id_num and
						self_reported = 'n'
					)
			) +
			(select max(tst_score)
					from test_scores_detail
					where 
					id_num = n.id_num and 
					tst_cde = 'ACT' and
					tst_elem = 'actrd' and
					exists ( select 1 from test_scores
						where
						id_num = test_scores_detail.id_num and
						self_reported = 'n'
					)
			) +
			(select max(tst_score)
					from test_scores_detail
					where 
					id_num = n.id_num and 
					tst_cde = 'ACT' and
					tst_elem = 'actmt' and
					exists ( select 1 from test_scores
						where
						id_num = test_scores_detail.id_num and
						self_reported = 'n'
					)
			) +
			(select max(tst_score)
					from test_scores_detail
					where 
					id_num = n.id_num and 
					tst_cde = 'ACT' and
					tst_elem = 'actsc' and
					exists ( select 1 from test_scores
						where
						id_num = test_scores_detail.id_num and
						self_reported = 'n'
					)
			)) / 4, 2,0) as decimal(10,0))
		) act,
		case when 1 = 
		(	select top 1 1 
			from ad_scholarship
			where
			id_num = n.id_num and
			scholarship_type = 'PLA' and
			isnull(date_scholarship_awarded, '') <> '' and
			isnull(date_scholarship_accepted, '') <> ''
		) then 'C' else 'I' end pla_status,
		city, state,
		(	select (select isnull(last_name, '')+isnull(first_name, '') from name_master 
				where
				id_num = org_id__ad and
				name_format = 'B'
				) 
			from ad_org_tracking
			where
			id_num = n.id_num and
			last_high_school = 'Y' and
			org_type_ad_ = 'HS'	
		) hs_name,
		( 	select table_desc from table_detail
			where
			table_value = religion and
			column_name = 'religion' 
		) religion,
				coalesce(dbo.race_ethnicity(n.id_num),
                dbo.detail(ethnic_group, 'ethnic_group', default, default), 'None reported') ethnicity
		from candidacy cd, biograph_master b, name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = case when isnull(n.current_address, '') in ('*LHP','PLCL') then n.current_address else '*LHP' end
		where
		n.id_num = cd.id_num and
		n.id_num = b.id_num and
		cur_candidacy = 'Y' and
		-- n.id_num = '731136' and
		n.id_num in (711002)
		order by last_name, first_name
			});
	$sth->execute ();
	while (my $contact_ref = $sth->fetchrow_hashref ()){
		# print "$contact_ref->{last_name}\n";
		m_strip_space ($contact_ref, $sth->{NAME});
		my ($act, $sat, $revised);
		if ($contact_ref->{sat}){
			$sat = $contact_ref->{sat};
			if ($contact_ref->{sat} == 1600){
				$revised = '36';
			} else {
				foreach my $range (@ranges){
					$range =~ /(.*)_(.*)/;
					if ($contact_ref->{sat} >= $1 && $contact_ref->{sat} <= $2){
						$revised = $convert{'a'.$range};
						last;
					}
				}
			}
			
		}
		if ($contact_ref->{act}){
			$act = $contact_ref->{act};
			if ($revised && $contact_ref->{act} > $revised){
				$revised = $contact_ref->{act};
				$act .= '*' if $contact_ref->{sat};
			} elsif ($revised){
				$sat .= '*';
			} else {
				$revised = $contact_ref->{act};
				$act .= '*';
			}
			
		}
		$revised = '' unless $revised;
		$contact_ref->{hs_gpa_weighted} = $contact_ref->{hs_gpa} unless $contact_ref->{hs_gpa_weighted};
		$contact_ref->{hs_gpa_weighted} = sprintf("%.2f", $contact_ref->{hs_gpa_weighted}) if $contact_ref->{hs_gpa_weighted};
#		if ($contact_ref->{uethnicbg} =~ /[ABHIOP]/){
#	#		$contact_ref->{unamefirst} .= '*';
#		}
		local $^W; # turn off strict flag
		# \t$contact_ref->{pla_status}
		push @load, "$contact_ref->{id_num}	$contact_ref->{first_name}	$contact_ref->{last_name}	$contact_ref->{gender}	$contact_ref->{Major1}	$act	$sat	$revised	$contact_ref->{hs_gpa_weighted}\t\t\t\t\t\t\t$contact_ref->{status}	$contact_ref->{city}	$contact_ref->{state}	$contact_ref->{hs_name}	$contact_ref->{religion}	$contact_ref->{ethnicity}\n";
	}
	open(OUT,">$global{g_path}reports/pla_spreadsheet.txt");
	print OUT @load; 
	close (OUT);
}

sub noellevitz {
	my (%type, %term, %fullpart, %hstype, $flag);
	$type{FF} = 'first-year';
	$type{TR} = 'transfer';
	$term{FA} = 'fall';
	$term{SP} = 'spring';
	$term{MA} = 'May-Term';
	$term{SU} = 'summer';
	$fullpart{F} = 'Full Time enrollment';
	$fullpart{P} = 'Part Time enrollment';
	$fullpart{'P1-5'} = 'Part Time 1-5 Hours';
	$fullpart{'P6-11'} = 'Part Time 6-11 Hours';
	$hstype{F} = 'Final';
	$hstype{O} = 'Official';
	$hstype{S} = 'Self-reported';
	$hstype{SP} = 'Partial';
	$hstype{ST} = 'Test';
	$hstype{U} = 'Unofficial';

	my ($count, %header, %requirements, @headers, $select, @problems, @update, @rows, @cover_sheet, @calls, @column_list, $overall_update_flag);

	my (@year, $auto);
#	if (param('auto')){
#		@year = ('2010 FA','2011 FA');
#		$auto = 0;
#	} else {
#	#	@year = ('2005 FA','2006 FA','2007 FA','2008 FA');
#	#	@year = ('2006 FA','2007 FA','2008 FA','2009 FA');
		@year = ('2012');
#		$auto = 1;
#	}
	my %translation = ('ucounty','County','key5','ID','unamelast','Last','unamefirst','First','dear','Dear','unamemid','Middle','key2','Term','department','Add_type','ubirthdate','Birthday','ufullpart','Full/Part','ugender','Gender','u_email','GC_Email','company','SSN');


	foreach my $year (@year){
		@cover_sheet = ();
		my @column = qw/
		*id_num
		last_name
		first_name
		middle_name
		addr_line_1-address1
		addr_line_2-address2
		city
		state
		zip
		birth_dte-Birth_Date
		*year_term
		*hs_grad_year
		*firstsource
		*Inq_binary
		*App_binary
		*Admit_binary
		*Deposit_binary
		*Enroll_binary
		*Canceled_binary
	/;
		my ($string);
		foreach (@column){
			my @split = split(/-/);
			my $name = $split[0];
			unless ($name =~ s/^\*//){
				if ($split[1] && $split[1] =~ /Date/){
					$string .= "convert(varchar(12), $name, 101) as $name, ";
				} else {
					$string .= "$name, ";
				}
			}
			if ($translation{$name}){
				push @cover_sheet, "$translation{$name}\t";
			} elsif ($split[1]){
				push @cover_sheet, "$split[1]\t";
			} else {
				push @cover_sheet, "$name\t";
			}
		}
		$cover_sheet[-1] =~ s/\t/\n/;
		my %leave;
		my $sth = $global{dbh_jenz}->prepare (qq{
			select top 100 $string n.id_num, right(stage, 3) stage,
			(	select top 1 case 
					when isnull(yr_of_graduation, '') <> '' and yr_of_graduation < 2011 then (yr_of_graduation + 1)
					when isnull(yr_of_graduation, '') <> '' then yr_of_graduation
					else convert(varchar(4), self_reported_graduation_dte, 112)
					end
				from ad_org_tracking
				where
				id_num = n.id_num and
				last_high_school = 'Y' and
				org_type_ad_ = 'HS'	
			) hs_grad_year,
			yr_cde + ' ' + trm_cde year_term,
			case when source_1 like 'x%' and source_1 not like 'XAP%' and source_1 not like 'XAW%' then 'App'
			else source_1 end firstsource
			from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = case when isnull(n.current_address, '') = '' then '*LHP' when isnull(n.current_address, '') not in ('*LHP','PLCL') then '*LHP' else current_address end,
			biograph_master b 
			left join candidacy cd on b.id_num = cd.id_num and CUR_CANDIDACY = 'Y'
			left join candidate c on cd.id_num = c.id_num
			left join candidate_udf u on c.id_num = u.id_num
			where
			n.id_num = b.id_num and
			(cd.yr_cde = '2012' and trm_cde = 'FA' or
			cd.yr_cde = '2011' and trm_cde in ('SP','MA','SU')) and
			cd.candidacy_type in ('f') and
			isnull(dept_cde, '') <> 'GAP' and
			isnull(name_sts, '') <> 'D' and
			-- candidacy_type in ('F','T','R','P','X') and
			(isnull(country, '') = '' or country = 'canada')
			-- n.id_num in ()
				});
		$sth->execute ();
		while (my $contact_ref = $sth->fetchrow_hashref ()){
			foreach (@column){
				my @split = split(/-/);
				my $name = $split[0];
				$name =~ s/^\*//;
				#	if ($name eq 'FullPart_des'){
				#	push @cover_sheet, "$fullpart{$contact_ref->{ufullpart}}\t";
				if ($name eq 'Inq_binary'){
					if ($contact_ref->{stage} >= '100'){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'App_binary'){
					if ($contact_ref->{stage} >= '400'){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'Admit_binary'){
					if ($contact_ref->{stage} >= '600'){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'Deposit_binary'){
					if ($contact_ref->{stage} >= '700'){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'Enroll_binary'){
					if ($contact_ref->{stage} >= '800'){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'Canceled_binary'){
					if ($contact_ref->{stage} == '790'){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} else {
					if ($contact_ref->{$name}){
						push @cover_sheet, "$contact_ref->{$name}\t";
					} else {
						push @cover_sheet, "\t";
					}
				}
			}
			push @cover_sheet, "\n";
		}
		# print @cover_sheet;
		open(OUT, ">$global{g_path}reports/noellevets/$year.txt");
		print OUT @cover_sheet;
		close (OUT);
	}
}

sub NRCCRU_Match {
	my (%type, %term, %fullpart, %hstype, $flag);
	$type{FF} = 'first-year';
	$type{TR} = 'transfer';
	$term{FA} = 'fall';
	$term{SP} = 'spring';
	$term{MA} = 'May-Term';
	$term{SU} = 'summer';
	$fullpart{F} = 'Full Time enrollment';
	$fullpart{P} = 'Part Time enrollment';
	$fullpart{'P1-5'} = 'Part Time 1-5 Hours';
	$fullpart{'P6-11'} = 'Part Time 6-11 Hours';
	$hstype{F} = 'Final';
	$hstype{O} = 'Official';
	$hstype{S} = 'Self-reported';
	$hstype{SP} = 'Partial';
	$hstype{ST} = 'Test';
	$hstype{U} = 'Unofficial';

	my ($count, %header, %requirements, @headers, $select, @problems, @update, @rows, @cover_sheet, @calls, @column_list, $overall_update_flag);

	my (@year, $auto);
#	if (param('auto')){
#		@year = ('2010 FA','2011 FA');
#		$auto = 0;
#	} else {
#	#	@year = ('2005 FA','2006 FA','2007 FA','2008 FA');
#	#	@year = ('2006 FA','2007 FA','2008 FA','2009 FA');
		@year = ('2013');
#		$auto = 1;
#	}
	my %translation = ('ucounty','County','key5','ID','unamelast','Last','unamefirst','First','dear','Dear','unamemid','Middle','key2','Term','department','Add_type','ubirthdate','Birthday','ufullpart','Full/Part','ugender','Gender','u_email','GC_Email','company','SSN');


	foreach my $year (@year){
		@cover_sheet = ();
		my @column = qw/
		*id_num
		last_name
		first_name
		middle_name
		addr_line_1-address1
		addr_line_2-address2
		city
		state
		zip
		birth_dte-Birth_Date
		*year_term
		*firstsource
		*firstsource_def
		email_address
		*Phone
		*Cell
		
	/;
		my ($string);
		foreach (@column){
			my @split = split(/-/);
			my $name = $split[0];
			unless ($name =~ s/^\*//){
				if ($split[1] && $split[1] =~ /Date/){
					$string .= "convert(varchar(12), $name, 101) as $name, ";
				} else {
					$string .= "$name, ";
				}
			}
			if ($translation{$name}){
				push @cover_sheet, "$translation{$name}\t";
			} elsif ($split[1]){
				push @cover_sheet, "$split[1]\t";
			} else {
				push @cover_sheet, "$name\t";
			}
		}
		$cover_sheet[-1] =~ s/\t/\n/;
		my %leave;
		my $sth = $global{dbh_jenz}->prepare (qq{
			select $string n.id_num, right(stage, 3) stage,
			(	select top 1 case 
					when isnull(yr_of_graduation, '') <> '' and yr_of_graduation < 2011 then (yr_of_graduation + 1)
					when isnull(yr_of_graduation, '') <> '' then yr_of_graduation
					else convert(varchar(4), self_reported_graduation_dte, 112)
					end
				from ad_org_tracking
				where
				id_num = n.id_num and
				last_high_school = 'Y' and
				org_type_ad_ = 'HS'	
			) hs_grad_year,
			yr_cde + ' ' + trm_cde year_term,
			dbo.gsc_cm_tel_format_sf(phone, '(xxx)xxx-xxxx') Phone, dbo.gsc_cm_tel_format_sf(n.mobile_phone, '(xxx)xxx-xxxx') Cell,
			case when source_1 like 'x%' and source_1 not like 'XAP%' and source_1 not like 'XAW%' then 'App'
			else source_1 end firstsource,
			(select source_desc from source_definition
			where
			source_cde = source_1 ) firstsource_def
			from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = case when isnull(n.current_address, '') = '' then '*LHP' when isnull(n.current_address, '') not in ('*LHP','PLCL') then '*LHP' else current_address end,
			biograph_master b 
			left join candidacy cd on b.id_num = cd.id_num and CUR_CANDIDACY = 'Y'
			left join candidate c on cd.id_num = c.id_num
			left join candidate_udf u on c.id_num = u.id_num
			where
			n.id_num = b.id_num and
			(cd.yr_cde in ('2013','2014') or
			yr_cde = 'UNK' and source_1 = 'AOSMM') and
			isnull(state, '') <> 'PR' and
			cd.candidacy_type in ('f') and
			isnull(dept_cde, '') <> 'GAP' and
			isnull(name_sts, '') <> 'D' and
			candidacy_type in ('F','T','R','P','X') and
			(isnull(country, '') = '' or country = 'canada') 

			and right(stage, 3) not like '_9%' and
			(	(isnull(addr_line_1, '') = '' or addr_sts = 'B') and
				(isnull(a.phone, 0) <> 0 or
				isnull(mobile_phone, 0) <> 0 or
				isnull(email_address, '') <> '')
			/* or
				isnull(a.phone, 0) = 0 and isnull(mobile_phone, 0) = 0 and
				(isnull(addr_line_1, '') <> '' and isnull(addr_sts, '') <> 'B' or
				isnull(email_address, '') <> '')
			or
				isnull(email_address, '') = '' and
				(isnull(a.phone, 0) <> 0 or
				isnull(mobile_phone, 0) <> 0 or
				isnull(addr_line_1, '') <> '' and isnull(addr_sts, '') <> 'B') */
			)
				});
		$sth->execute ();
		while (my $contact_ref = $sth->fetchrow_hashref ()){
			foreach (@column){
				my @split = split(/-/);
				my $name = $split[0];
				$name =~ s/^\*//;
				#	if ($name eq 'FullPart_des'){
				#	push @cover_sheet, "$fullpart{$contact_ref->{ufullpart}}\t";
				if ($name eq 'Inq_binary'){
					if ($contact_ref->{stage} >= '100'){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'App_binary'){
					if ($contact_ref->{stage} >= '400'){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'Admit_binary'){
					if ($contact_ref->{stage} >= '600'){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'Deposit_binary'){
					if ($contact_ref->{stage} >= '700'){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'Enroll_binary'){
					if ($contact_ref->{stage} >= '800'){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'Canceled_binary'){
					if ($contact_ref->{stage} == '790'){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} else {
					if ($contact_ref->{$name}){
						push @cover_sheet, "$contact_ref->{$name}\t";
					} else {
						push @cover_sheet, "\t";
					}
				}
			}
			push @cover_sheet, "\n";
		}
		# print @cover_sheet;
		open(OUT, ">$global{g_path}reports/nrccua/$year.txt");
		print OUT @cover_sheet;
		close (OUT);
	}
}

sub hs_name_check {
	my @list = "ID_NUM\tCorrect Name\tJenzabar Name\n";

	unless (open(IN, "$global{g_path}reports/hs_list/list.txt")){
		main::printer("Unable to open source file");
	}
	while (<IN>){
		chomp;
		s/\r//;
		my @split = split(/\t/);
		my $sth = $global{dbh_jenz}->prepare (qq{
			select n.id_num, last_name+isnull(first_name, '')+isnull(middle_name, '') name, org_cde ceeb from name_master n, org_master o
			where
			org_cde = ? and
			n.id_num = o.id_num and
			org_type = 'HS'
				});
		$sth->execute ($split[1]);
		if (my $hs_ref = $sth->fetchrow_hashref ()){
			if ($split[0] !~ /$hs_ref->{name}/i){
				$split[0] =~ s/(\w+)/\L\u$1/g;
				push @list, "$hs_ref->{id_num}\t$split[0]\t$hs_ref->{name}\n";
			}
		}
	}
	open(OUT, ">$global{g_path}reports/hs_list/to_correct.txt");
	print OUT @list;
}

sub rapid_insight_export {
	my (%type, %term, %fullpart, %hstype, $flag);
	$type{FF} = 'first-year';
	$type{TR} = 'transfer';
	$term{FA} = 'fall';
	$term{SP} = 'spring';
	$term{MA} = 'May-Term';
	$term{SU} = 'summer';
	$fullpart{F} = 'Full Time enrollment';
	$fullpart{P} = 'Part Time enrollment';
	$fullpart{'P1-5'} = 'Part Time 1-5 Hours';
	$fullpart{'P6-11'} = 'Part Time 6-11 Hours';
	$hstype{F} = 'Final';
	$hstype{O} = 'Official';
	$hstype{S} = 'Self-reported';
	$hstype{SP} = 'Partial';
	$hstype{ST} = 'Test';
	$hstype{U} = 'Unofficial';

	my ($count, %header, %requirements, @headers, $select, @problems, @update, @rows, @cover_sheet, @calls, @column_list, $overall_update_flag);

	my (@year, $auto);
#	if (param('auto')){
#		@year = ('2010 FA','2011 FA');
#		$auto = 0;
#	} else {
#	#	@year = ('2005 FA','2006 FA','2007 FA','2008 FA');
#	#	@year = ('2006 FA','2007 FA','2008 FA','2009 FA');
		@year = ('2010','2011','2012');
#		$auto = 1;
#	}
	my %translation = ('ucounty','County','key5','ID','unamelast','Last','unamefirst','First','dear','Dear','unamemid','Middle','key2','Term','department','Add_type','ubirthdate','Birthday','ufullpart','Full/Part','ugender','Gender','u_email','GC_Email','company','SSN');


	foreach my $year (@year){
		@cover_sheet = ();
		my @column = qw/
		*id_num
		first_name
		last_name
		preferred_name
		tier
		source_1
		middle_name
		*stage
		*App_binary
		*Admit_binary
		*Deposit_binary
		*Enroll_binary
		candidacy_type-Type
		trm_cde
		yr_cde
		addr_line_1-address1
		addr_line_2-address2
		city
		state
		zip
		*country
		load_p_f-fullpart
		gender
		birth_dte-Birth_Date
		*ethnicity
		marital_sts-Marital_Status
		lead
		counselor_initials
		*act
		*sat
		*gpa
		*hs_name
		*church
		*major
		legacy
	/;
#		fafsa_file_date-FAFSA_Filed_Date
#		UAPPLICDT-App_Date
#		UAPPFEEDT-App_Fee_Date
#		UESSAYDT-Essay_Date
#		UHSTRANDT-HS_Transcript_Date
#		UTESTGEDDT-GED_Date
#		UTESTDT-ACT_SAT_Date
#		UAPDT-AP_Score_Date
#		URECACADDT-Personal_Ref_Date
#		URECMINDT-Guide_Coun_Ref_Date
#		UCOLTRANDT-Col_Transcript_Date
#		UFAFSA-FAFSA_EFC
#		UAWARD-FA_Award_Date
#		UCOREFRTY-Core_40
#		UTWNTYFC-21st_Century
#		UNATMERIT-National_Merit
#		UPRESAWARD-PLA
#		UACADSCH-Academic_Sch
#		USTOLTZFUS-Stoltzfus
#		UFILECMPDT-File_Complete_Date
#		UDEPPDDT-Deposit_Date
#		UREGDT-Register_Date
#		UHOUSDT-Housing_Date
#		UPREDGPA-Predicted_GPA
	
		my ($string);
		foreach (@column){
			my @split = split(/-/);
			my $name = $split[0];
			unless ($name =~ s/^\*//){
				if ($split[1] && $split[1] =~ /Date/){
					$string .= "convert(varchar(12), $name, 101) as $name, ";
				} else {
					$string .= "$name, ";
				}
			}
			if ($translation{$name}){
				push @cover_sheet, "$translation{$name}\t";
			} elsif ($split[1]){
				push @cover_sheet, "$split[1]\t";
			} else {
				push @cover_sheet, "$name\t";
			}
		}
		$cover_sheet[-1] =~ s/\t/\n/;
		my %leave;
		my $sth = $global{dbh_jenz}->prepare (qq{
			select $string n.id_num, right(stage, 3) stage,
			coalesce(dbo.race_ethnicity(n.id_num),
		        	dbo.detail(ethnic_group, 'ethnic_group', default, default), 'None reported') ethnicity,
			( 	select table_desc from table_detail
				where
				table_value = country and
				column_name = 'country' 
			) country,
			cast(round ( 
			(select max(tst_score) 
				from test_scores_detail
				where 
				id_num = n.id_num and 
				tst_cde = 'SAT' and
				tst_elem = 'satv' and
				exists ( select 1 from test_scores
					where
					id_num = test_scores_detail.id_num and
					self_reported = 'n'
				)
			) +
			(select max(tst_score) 
				from test_scores_detail
				where 
				id_num = n.id_num and 
				tst_cde = 'SAT' and
				tst_elem = 'satw' and
				exists ( select 1 from test_scores
					where
					id_num = test_scores_detail.id_num and
					self_reported = 'n'
				)
			) +
			(select max(tst_score) 
				from test_scores_detail
				where 
				id_num = n.id_num and 
				tst_cde = 'SAT' and
				tst_elem = 'satm' and
				exists ( select 1 from test_scores
					where
					id_num = test_scores_detail.id_num and
					self_reported = 'n'
				)
			),2,0) as decimal(10,0)) sat_composit,
			(cast(round (
				((select max(tst_score)
						from test_scores_detail
						where 
						id_num = n.id_num and 
						tst_cde = 'ACT' and
						tst_elem = 'acten' and
						exists ( select 1 from test_scores
							where
							id_num = test_scores_detail.id_num and
							self_reported = 'n'
						)
				) +
				(select max(tst_score)
						from test_scores_detail
						where 
						id_num = n.id_num and 
						tst_cde = 'ACT' and
						tst_elem = 'actrd' and
						exists ( select 1 from test_scores
							where
							id_num = test_scores_detail.id_num and
							self_reported = 'n'
						)
				) +
				(select max(tst_score)
						from test_scores_detail
						where 
						id_num = n.id_num and 
						tst_cde = 'ACT' and
						tst_elem = 'actmt' and
						exists ( select 1 from test_scores
							where
							id_num = test_scores_detail.id_num and
							self_reported = 'n'
						)
				) +
				(select max(tst_score)
						from test_scores_detail
						where 
						id_num = n.id_num and 
						tst_cde = 'ACT' and
						tst_elem = 'actsc' and
						exists ( select 1 from test_scores
							where
							id_num = test_scores_detail.id_num and
							self_reported = 'n'
						)
				)) / 4, 2,0) as decimal(10,0))
			) act,
			(	select top 1 cast(round (gpa, 2,0) as decimal(10,2))
				from ad_org_tracking
				where
				id_num = n.id_num and
				last_high_school = 'Y' and
				org_type_ad_ = 'HS'	
			) gpa,
			(	select (select isnull(last_name, '')+isnull(first_name, '') from name_master 
					where
					id_num = org_id__ad and
					name_format = 'B'
					) 
				from ad_org_tracking
				where
				id_num = n.id_num and
				last_high_school = 'Y' and
				org_type_ad_ = 'HS'	
			) hs_name,
			(select isnull(last_name, '')+isnull(first_name, '') from name_master
			where
			id_num = (
				select id_num from org_master 
				where
				org_type = 'ch' and
				org_cde = b.udef_5a_1
				)
			) as church,
			dbo.GSC_MAJOR_CDE_TRANSL_SF(prog_cde) Major 
			from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = case when isnull(n.current_address, '') = '' then '*LHP' when isnull(n.current_address, '') not in ('*LHP','PLCL') then '*LHP' else current_address end,
			biograph_master b 
			left join candidacy cd on b.id_num = cd.id_num and CUR_CANDIDACY = 'Y'
			left join candidate c on cd.id_num = c.id_num
			left join candidate_udf u on c.id_num = u.id_num
			where
			n.id_num = b.id_num and
			cd.yr_cde = ? and trm_cde = 'FA' and
			cd.candidacy_type in ('f') and
			isnull(dept_cde, '') <> 'GAP' and
			isnull(name_sts, '') <> 'D'
				});
		$sth->execute ($year);
		while (my $contact_ref = $sth->fetchrow_hashref ()){
			foreach (@column){
				my @split = split(/-/);
				my $name = $split[0];
				$name =~ s/^\*//;
				#	if ($name eq 'FullPart_des'){
				#	push @cover_sheet, "$fullpart{$contact_ref->{ufullpart}}\t";
				if ($name eq 'App_binary'){
					if ($contact_ref->{stage} >= '400'){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'Admit_binary'){
					if ($contact_ref->{stage} >= '600'){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'Deposit_binary'){
					if ($contact_ref->{stage} >= '700'){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'Enroll_binary'){
					if ($contact_ref->{stage} >= '800'){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} else {
					if ($contact_ref->{$name}){
						push @cover_sheet, "$contact_ref->{$name}\t";
					} else {
						push @cover_sheet, "\t";
					}
				}
			}
		}
		# print @cover_sheet;
		open(OUT, ">$global{g_path}reports/rapid_insight/$year.txt");
		print OUT @cover_sheet;
		close (OUT);
	}
}

sub hs_certificates {
	my ($count, %header, @load_data, %ceeb);

	my %fa_award;
	my @awards = (1 .. 5);

	$fa_award{3571} = 'Athletic Award - Cross Country';
	$fa_award{3572} = 'Athletic Award - Golf';
	$fa_award{3573} = 'Athletic Award - Soccer';
	$fa_award{3574} = 'Athletic Award - Softball';
	$fa_award{3575} = 'Athletic Award - Tennis';
	$fa_award{3576} = 'Athletic Award - Track & Field';
	$fa_award{3577} = 'Athletic Award - Volleyball';
	$fa_award{3569} = 'Athletic Award - Baseball';#
	$fa_award{3570} = 'Athletic Award - Basketball';#
	$fa_award{3805} = 'Music Achievement Scholarship';
	$fa_award{3873} = 'Music Achievement Scholarship';
	$fa_award{6246} = 'Music Excellence Scholarship';
	$fa_award{3685} = 'Gorsline Communication Scholarship';
	$fa_award{3684} = 'Gorsline Business Scholarship';
	$fa_award{3686} = 'Gorsline Theater Award';
	$fa_award{3861} = 'Stoltzfus Recognition Award';
	$fa_award{3583} = 'Anglemeyer Education Scholarship';
	$fa_award{3912} = 'CITL Scholarship';
	# no one dream scholarship $fa_award{3912} = 'CITL Scholarship'; # Dream
	$fa_award{3872} = 'Swallen Mission Scholarship';

	push my @load, "id_num\tcounselor\tlast\tfirst\tmid\taddr1\tcity\tstate\tzip\tstatus\taward1\taward2\taward3\taward4\taward5\ths\tceeb\taddress1\taddress2\thscity\thsstate\thszip\n";
	push my @load_names, "id_num\tcounselor\tlast\tfirst\tmid\taddr1\tcity\tstate\tzip\tstatus\taward1\taward2\taward3\taward4\taward5\ths\tceeb\taddress1\taddress2\thscity\thsstate\thszip\tnames\n";
	my ($email, $contsupp, $accountno, @hold_load, $names);
	my $sth = $global{dbh_jenz}->prepare (qq{
		select n.id_num, first_name, last_name, 
		left(middle_name, 1) as mid_ini,
		counselor_initials counselor,
		cur_yr year, cur_trm term,	
		(select top 1 'Y' from ad_scholarship
		where
		id_num = n.id_num and
		yr_cde = cd.yr_cde and
		trm_cde = cd.trm_cde and 
		scholarship_type = 'PLA' and
		transferred_to_pf = 'y'
		) pla,
		(select top 1 'Y' from ad_scholarship
		where
		id_num = n.id_num and
		yr_cde = cd.yr_cde and
		trm_cde = cd.trm_cde and 
		scholarship_type = 'citl' and
		transferred_to_pf = 'y'
		) citl,
		c.udef_2a_2 natl_merit,
		c.udef_2a_4 acad_schol,
		case c.udef_2a_4
		when 'P' then 'President''s Leadership Award'
		when 'M' then 'Menno Simons Scholarship'
		when 'W' then 'Wens Honors Scholarship'
		when 'Y' then 'Yoder Honors Scholarship'
		when 'G' then 'Grebel Honors Scholarship'
		when 'K' then 'Kratz Honors Scholarship' 
		when 'A' then 'Achievement Scholarship' 
		end as scholarship,
		right(stage, 3) status,
		(select candidacy_typ_desc from candidacy_type_def where candidacy_type = cd.candidacy_type) type,
		addr_line_1,
		city, state, zip,
		( 	select table_desc from table_detail
			where
			table_value = country and
			column_name = 'country' 
		) Country,
		(	select (select isnull(last_name, '')+isnull(first_name, '') from name_master 
				where
				id_num = org_id__ad and
				name_format = 'B'
				) 
			from ad_org_tracking
			where
			id_num = n.id_num and
			last_high_school = 'Y' and
			org_type_ad_ = 'HS'	
		) last_hs,
		(select org_cde_ad 
			from ad_org_tracking
			where
			id_num = n.id_num and
			last_high_school = 'Y' and
			org_type_ad_ = 'HS'	
		) hs_ceeb,
		(select 'yes' 
			from ad_org_tracking
			where
			id_num = n.id_num and
			last_high_school = 'Y' and
			org_type_ad_ = 'HS'	and
			udef_2a_1 = 'F'
		) trans_final,
		(select org_id__ad
			from ad_org_tracking
			where
			id_num = n.id_num and
			last_high_school = 'Y' and
			org_type_ad_ = 'HS'	
		) hs_id
		from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = case when isnull(n.current_address, '') = '' then '*LHP' when isnull(n.current_address, '') not in ('*LHP','PLCL') then '*LHP' else current_address end,
		biograph_master b 
		left join candidacy cd on b.id_num = cd.id_num and CUR_CANDIDACY = 'Y'
		left join candidate c on cd.id_num = c.id_num
		left join candidate_udf u on c.id_num = u.id_num
		where
		n.id_num = b.id_num and
		cd.yr_cde = '2013' and trm_cde = 'FA' and
		right(stage, 3) not like '_9%' and
		(cd.candidacy_type = 'F' or
		c.udef_1a_2 = 'U' and cd.candidacy_type = 'I') and
		-- load_p_f = 'F' and 
		right(stage, 3) >= '600' and
		exists (
			select 1 from ad_org_tracking
			where
			id_num = n.id_num and
			org_type_ad_ = 'HS' and
			last_high_school = 'Y' and
			(self_reported_graduation_dte > '12/1/2012' or
			isnull(self_reported_graduation_dte, '') = '')
		)
		order by hs_ceeb
			});
	$sth->execute ();
	while (my $contact_ref = $sth->fetchrow_hashref ()){
		local $^W; # turn off strict flag
		my (%awards);
		if ($contact_ref->{pla}){
			$awards{1} = "President's Leadership Award";
		} elsif ($contact_ref->{scholarship}){
			$awards{1} = $contact_ref->{scholarship};
		}
		if ($contact_ref->{natl_merit} eq 'F'){
			$awards{2} = "National Merit Finalist";
		} elsif ($contact_ref->{natl_merit} eq 'S'){
			$awards{2} = "National Merit Semifinalist";
		}

		my $test;
		$test++ if ($contact_ref->{scholarship} || $contact_ref->{pla} eq 'Y' || $contact_ref->{natl_merit} =~ /[fs]/i || $contact_ref->{citl} =~ /yi/);
		my $sth = $global{dbh_jenz}->prepare (qq{
			SELECT v.codeid
			FROM  gsc_pf_funds v, GSC_FAID f
			where  f.id = ? and
			f.yr = 2013 and
			f.aidcode = v.codeid and
			f.yr = v.yr and
			v.codeid in (3571,3572,3573,3574,3575,3576,3577,3569,3570,3805,3873,3685,3684,3686,3861,3583,3912,3872)
				});
		$sth->execute ($contact_ref->{id_num});
		while (my $oracle_ref = $sth->fetchrow_hashref ()){
			foreach (@awards){
				next if $awards{$_};
				$test++;
				$awards{$_} = $fa_award{$oracle_ref->{codeid}};
				last;
			}
		}
		next unless $test;
		$sth = $global{dbh_jenz}->prepare (qq{
			select n.id_num, isnull(last_name, '')+isnull(first_name, '') name,
			addr_line_1 address1, addr_line_2 address2,
			city, state, zip,
			( 	select table_desc from table_detail
				where
				table_value = country and
				column_name = 'country' 
			) Country
			from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = case when isnull(n.current_address, '') = '' then '*LHP' when isnull(n.current_address, '') not in ('*LHP','PLCL') then '*LHP' else current_address end
			where
			n.id_num = ?

				});
		$sth->execute ($contact_ref->{hs_id});
		if (my $institution_name_ref = $sth->fetchrow_hashref ()){
			if ($ceeb{$contact_ref->{hs_ceeb}}){
				$names .= "$contact_ref->{first_name} $contact_ref->{last_name}, ";
				push @load, "$contact_ref->{id_num}\t$contact_ref->{counselor}\t$contact_ref->{last_name}\t$contact_ref->{first_name}\t$contact_ref->{mid_ini}\t$contact_ref->{addr_line_1}\t$contact_ref->{city}\t$contact_ref->{state}\t$contact_ref->{zip}\t$contact_ref->{status}\t$awards{1}\t$awards{2}\t$awards{3}\t$awards{4}\t$awards{5}\t\t$contact_ref->{hs_ceeb}\t\t\t\t\t\n";
			} else {
				$ceeb{$contact_ref->{hs_ceeb}}++;
				push @load, "$contact_ref->{id_num}\t$contact_ref->{counselor}\t$contact_ref->{last_name}\t$contact_ref->{first_name}\t$contact_ref->{mid_ini}\t$contact_ref->{addr_line_1}\t$contact_ref->{city}\t$contact_ref->{state}\t$contact_ref->{zip}\t$contact_ref->{status}\t$awards{1}\t$awards{2}\t$awards{3}\t$awards{4}\t$awards{5}\t$institution_name_ref->{name}\t$contact_ref->{hs_ceeb}\t$institution_name_ref->{address1}\t$institution_name_ref->{address2}\t$institution_name_ref->{city}\t$institution_name_ref->{state}\t$institution_name_ref->{zip}\n";
				if (@hold_load){
					$names =~ s/, $//;
					if ($names =~ /,/){
						$names = "final high school transcripts for $names";
					} else {
						$names = "a final high school transcript for $names";
					}
					$hold_load[-1] =~ s/\n/\t$names\n/;
					push @load_names, @hold_load;
					@hold_load = ();
					$names = '';
				}
				$names .= "$contact_ref->{first_name} $contact_ref->{last_name}, ";
				push @hold_load, "$contact_ref->{id_num}\t$contact_ref->{counselor}\t$contact_ref->{last_name}\t$contact_ref->{first_name}\t$contact_ref->{mid_ini}\t$contact_ref->{addr_line_1}\t$contact_ref->{city}\t$contact_ref->{state}\t$contact_ref->{zip}\t$contact_ref->{status}\t$awards{1}\t$awards{2}\t$awards{3}\t$awards{4}\t$awards{5}\t$institution_name_ref->{name}\t$contact_ref->{hs_ceeb}\t$institution_name_ref->{address1}\t$institution_name_ref->{address2}\t$institution_name_ref->{city}\t$institution_name_ref->{state}\t$institution_name_ref->{zip}\n";;
			}
		} else {
			push @load, "$contact_ref->{id_num}\t$contact_ref->{counselor}\t$contact_ref->{last_name}\t$contact_ref->{first_name}\t$contact_ref->{mid_ini}\t$contact_ref->{addr_line_1}\t$contact_ref->{city}\t$contact_ref->{state}\t$contact_ref->{zip}\t$contact_ref->{status}\t$awards{1}\t$awards{2}\t$awards{3}\t$awards{4}\t$awards{5}\t\t\t\t\t\t\t\n";
		}
	}
	if (@hold_load){
		if ($names =~ s/(.*), (.*)$/$1 and $2/){
			$names = "final high school transcripts for $names\n";
		} else {
			$names = "a final high school transcript for $names\n";
		}
		$hold_load[-1] =~ s/\n/$names/;
		push @load_names, @hold_load;
	}
	open(OUT1, ">$global{g_path}reports/certificates/hs_with_names.txt");
	print OUT1 @load_names;
	close (OUT1);

	open(OUT, ">$global{g_path}reports/certificates/list.txt");
	print OUT @load;
	close (OUT);
}

sub paper_vs_web_app {
	my %counts;
	local $^W; # turn off strict flag
	my $sth = $global{dbh_jenz}->prepare (qq{
		select n.id_num, first_name, last_name, source_1, source_2, source_3, source_4, source_5, source_6, source_7, source_8, source_9, source_10,
		convert(varchar(12), source_dte_1, 112) date1,
		convert(varchar(12), source_dte_2, 112) date2,
		convert(varchar(12), source_dte_3, 112) date3,
		convert(varchar(12), source_dte_4, 112) date4,
		convert(varchar(12), source_dte_5, 112) date5,
		convert(varchar(12), source_dte_6, 112) date6,
		convert(varchar(12), source_dte_7, 112) date7,
		convert(varchar(12), source_dte_8, 112) date8,
		convert(varchar(12), source_dte_9, 112) date9,
		convert(varchar(12), source_dte_10, 112) date10
		from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = '*LHP',
		biograph_master b 
		left join candidacy cd on b.id_num = cd.id_num and CUR_CANDIDACY = 'Y'
		left join candidate c on cd.id_num = c.id_num
		left join candidate_udf u on c.id_num = u.id_num
		where
		n.id_num = b.id_num and
		cd.yr_cde = '2011' and trm_cde = 'FA' and
		cd.candidacy_type in ('F','I') and
		load_p_f = 'f' and
		right(stage, 3) >= '800'
			});
	$sth->execute ();
	while (my $contact_ref = $sth->fetchrow_hashref ()){
		my ($app_source, $last_date);
		foreach (1 .. 10){
			my $source = 'source_'.$_;
			my $date = 'date'.$_;
			if ($contact_ref->{$source} =~ /XWCAP|XWAAP|XPAPP/){
				if ($last_date < $contact_ref->{$date}){
					$app_source = $contact_ref->{$source};
					$last_date = $contact_ref->{$date};
				}
			}
		}
		if ($app_source){
			$counts{$app_source}++;
		} else {
			print "$contact_ref->{id_num} no app source\n";
		}
	}
	print "common app - $counts{XWCAP}\n";
	print "online app - $counts{XWAAP}\n";
	print "paper app - $counts{XPAPP}\n";
}

sub convention_list {
	my (%counselor, %coundear, %countitle, %counphone, %counemail);
	open(IN,"$global{g_path}misc/convention_list/list.txt");


	my ($count, %header, @data, @list);
	push @list, "id_num\tjenz_first\tjenz_last\tlist_first\tlist_last\tcity\tstate\tcounselor\n";
	while (<IN>){
		$count++;
		chomp;
	#	next if $count > 1 && $count < 176;
	#	last if $count > 100;
		s/\r//;
		my @info = split(/\t/);
		if ($count == 1){
			my @headers = split(/\t/, $_);
			my $countheaders = '0';
			foreach my $key (@headers){
				$key =~ s/[\/()'-]//g;
	#			$key =~ s/ /_/g;
	#			$key = "\L$key";
				$header{$key} = $countheaders;
				$countheaders++;
			}
			next;	
		}
	next unless @info[$header{grade}] == 12;
	@info[$header{hphone}] =~ s/[^\d]//g;
	my $sth = $global{dbh_jenz}->prepare (qq{
		select n.id_num, first_name, last_name, counselor_initials, city, state
		from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = '*LHP',
		biograph_master b 
		left join candidacy cd on b.id_num = cd.id_num and CUR_CANDIDACY = 'Y'
		left join candidate c on cd.id_num = c.id_num
		left join candidate_udf u on c.id_num = u.id_num
		where
		n.id_num = b.id_num and
		cd.yr_cde = '2011' and trm_cde = 'FA' and
		right(stage, 3) >= '700' and
		right(stage, 2) not like '9_' and
		(phone = ? or
		? = (select top 1 addr_line_1
		from address_master
		where id_num = n.id_num and
		addr_cde in ('*EML','PPEM','EML2') and
		addr_line_1 not like '%goshen.edu'
		order by case when addr_cde = '*EML' then 1
		when addr_cde = 'PPEM' then 2
		else 3
		end
		) or 
		first_name = ? and last_name = ?)
			});
	$sth->execute (@info[$header{hphone}], @info[$header{email}], @info[$header{first_name}], @info[$header{last_name}]);
	if (my $contact_ref = $sth->fetchrow_hashref ()){
		push @list, "$contact_ref->{id_num}\t$contact_ref->{first_name}\t$contact_ref->{last_name}\t@info[$header{first_name}]\t@info[$header{last_name}]\t$contact_ref->{city}\t$contact_ref->{state}\t$contact_ref->{counselor_initials}\n";
	}
#	print "@info[$header{first_name}] @info[$header{last_name}] <@info[$header{email}]>\n";
	# last;
	}
	open(OUT,">$global{g_path}misc/convention_list/deposits.txt");
	print OUT @list;
	close OUT;
}

sub moodle_test_list {
	my @list;
	my $sth = $global{dbh_jenz}->prepare (qq{
		select n.id_num, first_name, last_name, counselor_initials, city, state
		from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = '*LHP',
		biograph_master b 
		left join candidacy cd on b.id_num = cd.id_num and CUR_CANDIDACY = 'Y'
		left join candidate c on cd.id_num = c.id_num
		left join candidate_udf u on c.id_num = u.id_num
		where
		n.id_num = b.id_num and
		cd.yr_cde = '2013' and trm_cde = 'FA' and
		right(stage, 3) >= '700' and
		right(stage, 2) not like '9_' and
		(test_math = 'yes' or
		test_spanish = 'yes')
		/* (test_bible = 'yes' or
		test_math = 'yes' and test_math_type = 'Placement' or
		test_spanish = 'yes' and test_spanish_type = 'Placement' or
		test_french = 'yes' and test_french_type = 'Placement') */
			});
	$sth->execute ();
	while (my $contact_ref = $sth->fetchrow_hashref ()){
		push @list, "add, student, $contact_ref->{id_num}, 1213-OCT\n";
	#	print "$contact_ref->{id_num}\n";

	}
	open(OUT,">/home/amosmk/share/Moodle/csv_enrollments.txt");
	print OUT @list;
#	print "working\n";
}

sub tests_needed {
	my @list;
	my $sth = $global{dbh_jenz}->prepare (qq{
		select n.id_num, first_name, last_name, counselor_initials, city, state,
		cast(round ( 
		(select max(tst_score) 
			from test_scores_detail
			where 
			id_num = n.id_num and 
			tst_cde = 'SAT' and
			tst_elem = 'satm' and
			exists ( select 1 from test_scores
				where
				id_num = test_scores_detail.id_num and
				self_reported = 'n'
			)
		),2,0) as decimal(10,0)) sat_math,
		(cast(round (
			(select max(tst_score)
					from test_scores_detail
					where 
					id_num = n.id_num and 
					tst_cde = 'ACT' and
					tst_elem = 'actmt' and
					exists ( select 1 from test_scores
						where
						id_num = test_scores_detail.id_num and
						self_reported = 'n'
					)
			), 2,0) as decimal(10,0))
		) act_math,
		(cast(round (
			(select max(tst_score)
					from test_scores_detail
					where 
					id_num = n.id_num and 
					tst_cde = 'AP' and
					tst_elem in ('cab','cbc') and
					exists ( select 1 from test_scores
						where
						id_num = test_scores_detail.id_num and
						self_reported = 'n'
					)
			), 2,0) as decimal(10,0))
		) ap_score,
		(select cast(round (max(tst_score), 2,0) as decimal(10,0))
					from test_scores_detail
					where 
					id_num = n.id_num and 
					tst_cde = 'sat' and
					tst_elem = 'satv' and
					exists ( select 1 from test_scores
						where
						id_num = test_scores_detail.id_num and
						self_reported = 'n'
					)
			) sat_reading,
		(select cast(round (max(tst_score), 2,0) as decimal(10,0))
					from test_scores_detail
					where 
					id_num = n.id_num and 
					tst_cde = 'ACT' and
					tst_elem = 'acten' and
					exists ( select 1 from test_scores
						where
						id_num = test_scores_detail.id_num and
						self_reported = 'n'
					)
			) act_english	
		from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = '*LHP',
		biograph_master b 
		left join candidacy cd on b.id_num = cd.id_num and CUR_CANDIDACY = 'Y'
		left join candidate c on cd.id_num = c.id_num
		left join candidate_udf u on c.id_num = u.id_num
		where
		n.id_num = b.id_num and
		-- n.id_num = '712142' and
		cd.yr_cde = '2013' and trm_cde = 'FA' and
		right(stage, 3) >= '700' and
		right(stage, 2) not like '9_'
			});
	$sth->execute ();
	while (my $contact_ref = $sth->fetchrow_hashref ()){
		my $skip;
		$skip++ if $contact_ref->{act_math} && $contact_ref->{act_math} <=23;
		$skip++ if $contact_ref->{sat_math} && $contact_ref->{sat_math} <= 540;
		if (!$skip && $contact_ref->{sat_math} && $contact_ref->{sat_math} >= 480 && $contact_ref->{sat_math} <= 540 || $contact_ref->{act_math} && $contact_ref->{act_math} >= 20 && $contact_ref->{act_math} <=23){
		#	print "$contact_ref->{id_num}\n";
			my $sth = $global{dbh_jenz}->prepare (qq{
				update candidate_udf set test_math = 'Yes'
				where
				id_num = ?
					});
			$sth->execute ($contact_ref->{id_num});
		} elsif ($contact_ref->{sat_math} && $contact_ref->{sat_math} >= 550 || $contact_ref->{act_math} && $contact_ref->{act_math} >= 24 || $contact_ref->{ap_score} && $contact_ref->{ap_score} >= 4){ 
			my $sth = $global{dbh_jenz}->prepare (qq{
				update candidate_udf set test_math = 'No', test_math_type = 'Req Met'
				where
				id_num = ?
					});
			$sth->execute ($contact_ref->{id_num});
		} else {
			my $sth = $global{dbh_jenz}->prepare (qq{
				update candidate_udf set test_math = 'No', test_math_type = 'Math 105'
				where
				id_num = ?
					});
			$sth->execute ($contact_ref->{id_num});
		}
		if ($contact_ref->{sat_reading} && $contact_ref->{sat_reading} <= 470 || $contact_ref->{act_english} && $contact_ref->{act_english} <= 19){
			my $sth = $global{dbh_jenz}->prepare (qq{
				update candidate_udf set test_english = '105'
				where
				id_num = ?
					});
			$sth->execute ($contact_ref->{id_num});
		}
	}
}

sub naccap_addresses {
	push my @history, "userid\taccountno\tsrectype\trectype\tondate\tactvcode\tresultcode\tref\tnote\n";
	my (%header, $count, @data, $region);
	open(IN,"$global{g_path}reports/naccap/fairs.txt");
	push my @list, "Region	Fair	First	Last	Address 1	Address 2	City	State	Zip Code\n";
	while (<IN>){
		$count++;
		chomp;
		s/\r//;
		my @info = split(/\t/);
		if ($count == 1){
			my @headers = split(/\t/);
			my $countheaders = '0';
			foreach my $key (@headers){
				$key =~ s/[\/()'-]//g;
				$key =~ s/ /_/g;
				$header{$key} = $countheaders;
				$countheaders++;
			}		
			next;
		}
		my $string;
#		my $prw = '05%';
#		my $tier = "'tier 1','tier 2'";
	#	next unless "@info[$header{region}] _ @info[$header{r_number}]" eq 'north_central _ 4';
		for (my $i = 1; $i <= 4; $i++) {
			if (@info[$header{"fair$i"}] && @info[$header{"zip$i"}]){
#				$prw = 'unmatch' if @info[$header{"prw$i"}] eq 'yes';
#				$tier = "'tier no'" if @info[$header{"prw$i"}] eq 'no';
				my $found_ref;
				my $sth = $global{dbh_jenz}->prepare (qq{
					select longitude, latitude, zip, city, state from gsc_zip_code
					where
					zip = ?
						});
				$sth->execute (@info[$header{"zip$i"}]);
				unless ($found_ref = $sth->fetchrow_hashref ()){
					print "@info[$header{'fair'.$i}] - @info[$header{'zip'.$i}] not found in gsc_zip_code\n";
					exit;
				}
				my %zips;
				my $distance = '90';
				$distance = @info[$header{"dist$i"}] if @info[$header{"dist$i"}];
				my %coordinate_limit; 
				$coordinate_limit{long_upper} = ($found_ref->{longitude} + 1.5);
				$coordinate_limit{long_lower} = ($found_ref->{longitude} - 1.5);
				$coordinate_limit{lat_upper} = ($found_ref->{latitude} + 1.5);
				$coordinate_limit{lat_lower} = ($found_ref->{latitude} - 1.5);
				$sth = $global{dbh_jenz}->prepare (qq{
					select z2.zip, z2.city, z2.state
					from gsc_zip_code z1, gsc_zip_code z2
					where z1.zip = ? and
					round(acos((sin(z1.latitude * 0.017453293) * sin(z2.latitude * 0.017453293)) + (cos(z1.latitude * 0.017453293) * cos(z2.latitude * 0.017453293) * cos((z2.longitude*0.017453293)-(z1.longitude*0.017453293)))) * 3956, 4) <= ?
						});
				 $sth->execute (@info[$header{"zip$i"}], $distance);
			#	 $sth->execute (@info[$header{"zip$i"}], $coordinate_limit{long_lower}, $coordinate_limit{long_upper}, $coordinate_limit{lat_lower}, $coordinate_limit{lat_upper}, $found_ref->{latitude}, $found_ref->{longitude}, @info[$header{"zip$i"}], $distance);
				while (my $radius_ref = $sth->fetchrow_hashref ()){
					$radius_ref->{city} =~ s/'//g;
					$radius_ref->{state} =~ s/'//g;
					$zips{$radius_ref->{zip}} = "$radius_ref->{city}_$radius_ref->{state}";
				}
				while (my($name, $value) = each(%zips)){
					my @split = split(/_/, $value);
					$string .= "(zip like '$name%' or city = '$split[0]' and state = '$split[1]') or ";
				}
	#			$string .= "(zip like '$found_ref->{zip}%' or city = '$found_ref->{city}' and state = '$found_ref->{state}') or ";
			}
		}
		$string =~ s/ or $//;
		my $total_count;
		local $^W; # turn off strict flag
		my $sth = $global{dbh_jenz}->prepare (qq{
			select n.id_num, preferred_name, first_name, last_name,
			addr_line_1 address1, addr_line_2 address2,
			city, state, left(zip, 5) zip,
			( 	select table_desc from table_detail
				where
				table_value = country and
				column_name = 'country' 
			) country
			from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = case when isnull(n.current_address, '') = '' then '*LHP' when isnull(n.current_address, '') not in ('*LHP','PLCL') then '*LHP' else current_address end,
			biograph_master b 
			left join candidacy cd on b.id_num = cd.id_num and CUR_CANDIDACY = 'Y'
			left join candidate c on cd.id_num = c.id_num
			left join candidate_udf u on c.id_num = u.id_num
			where
			n.id_num = b.id_num and
			cd.yr_cde in ('2015','2014') and trm_cde = 'FA' and
			right(stage, 3) not like '_9%' and
			cd.candidacy_type in ('f') and
			isnull(dept_cde, '') <> 'GAP' and
			isnull(name_sts, '') <> 'D' and
			-- right(stage, 3) >= '160' and
			($string)
				});
		$sth->execute (); 
		while (my $contact_ref = $sth->fetchrow_hashref ()){
			$total_count++;
#			push @history, "AMOSMK\t$contact_ref->{accountno}\tF\tF\t9/15/07\t\tSNT\tNACCAP_FC @info[$header{Region}] @info[$header{R_number}] fair postcard\t\n";
			push @list, "@info[$header{Region}]\t@info[$header{fair1}]\t$contact_ref->{preferred_name}	$contact_ref->{last_name}	$contact_ref->{address1}	$contact_ref->{address2}	$contact_ref->{city}	$contact_ref->{state}	$contact_ref->{zip}\n";
		}
		if ($total_count){
	#		open(OUT,">$global{g_path}reports/naccap/@info[$header{Region}] _ @info[$header{R_number}].txt");
	#		print OUT @list;
	#		close (OUT);
			print "@info[$header{Region}] _ @info[$header{fair1}] @info[$header{R_number}] = $total_count\n";
		} 
	}
	open(OUT,">$global{g_path}reports/naccap/list.txt");
	print OUT @list;
	close (OUT);
}

sub tier_calibrate {
#Weight individual variable with menu:
#Total enrolled/class size * x/total category

# Weight each category having 1/0
# class size/quantity of 1's

##first source
##gender
##state
##legacy (giving/non giving parents)
##test scores
##fafsa
##current siblings
##parent employees at gc
##visits
#national merit
#Completed call
#Athletes
#Music
##App
##Admit
##Deposit
##incomplete app
##denomination
#Ap scores
#High schools
#church
#Custom evaluation/rating by callers and counselors
#Distance, Would that matter
#GPA and OUT of state vs in state and menno non
#days between apply and start term

	my $sth = $global{dbh_mysql}->prepare (qq{
		delete from neural_menu	
		where
		nm_type = 'F'
			});
	$sth->execute ();

	# source
	$sth = $global{dbh_jenz}->prepare (qq{
		select source_1, count(*) count from candidate c, candidacy cd
		where
		c.id_num = cd.id_num and
		cur_candidacy = 'Y' and
		yr_cde = '2011' and
		trm_cde = 'FA' and
		candidacy_type = 'F' and
		isnull(source_1, '') <> ''
		group by source_1
			});
	$sth->execute ();
	while (my $data_ref = $sth->fetchrow_hashref ()){
	#	print "$data_ref->{source_1}\n";

		my $sth = $global{dbh_jenz}->prepare (qq{
			select count(*) count from candidate c, candidacy cd
			where
			c.id_num = cd.id_num and
			cur_candidacy = 'Y' and
			yr_cde = '2011' and
			trm_cde = 'FA' and
			candidacy_type = 'F' and
			source_1 = ? and
			right(stage, 3) >= '800'
			having count(*) > 0
				});
		$sth->execute ($data_ref->{source_1});
		if (my $enroll_ref = $sth->fetchrow_hashref ()){
			my $num = ($enroll_ref->{count} * $data_ref->{count} / 7699);
			my $decimal = ($num / $data_ref->{count});
			$num = sprintf("%.2f", $num);
			my $sth = $global{dbh_mysql}->prepare (qq{
				insert neural_menu set nm_type = 'F', nm_variable = 'source', nm_code = ?, nm_likelyhood = ?, nm_decimal = ?
					});
			$sth->execute ($data_ref->{source_1}, "$num/$data_ref->{count}", $decimal);
		} 
	}

	#gender
	$sth = $global{dbh_jenz}->prepare (qq{
		select gender, count(*) count from candidate c, candidacy cd, biograph_master b
		where
		c.id_num = cd.id_num and
		c.id_num = b.id_num and
		cur_candidacy = 'Y' and
		yr_cde = '2011' and
		trm_cde = 'FA' and
		candidacy_type = 'F' and
		isnull(gender, '') <> ''
		group by gender
			});
	$sth->execute ();
	while (my $data_ref = $sth->fetchrow_hashref ()){
		my $sth = $global{dbh_jenz}->prepare (qq{
			select count(*) count from candidate c, candidacy cd, biograph_master b
			where
			c.id_num = cd.id_num and
			c.id_num = b.id_num and
			cur_candidacy = 'Y' and
			yr_cde = '2011' and
			trm_cde = 'FA' and
			candidacy_type = 'F' and
			gender = ? and
			right(stage, 3) >= '800'
			having count(*) > 0
				});
		$sth->execute ($data_ref->{gender});
		if (my $enroll_ref = $sth->fetchrow_hashref ()){
			my $num = ($enroll_ref->{count} * $data_ref->{count} / 7699);
			my $decimal = ($num / $data_ref->{count});
			$num = sprintf("%.2f", $num);
			my $sth = $global{dbh_mysql}->prepare (qq{
				insert neural_menu set nm_type = 'F', nm_variable = 'gender', nm_code = ?, nm_likelyhood = ?, nm_decimal = ?
					});
			$sth->execute ($data_ref->{gender}, "$num/$data_ref->{count}", $decimal);
		} 
	}
	
	# state
	$sth = $global{dbh_jenz}->prepare (qq{
		select state, count(*) count 
		from candidate c, candidacy cd, name_master n
		left join address_master a on a.id_num = n.id_num and a.addr_cde = '*LHP'
		where
		n.id_num = cd.id_num and
		c.id_num = cd.id_num and
		cur_candidacy = 'Y' and
		yr_cde = '2011' and
		trm_cde = 'FA' and
		candidacy_type = 'F' and
		isnull(state, '') <> ''
		group by state
			});
	$sth->execute ();
	while (my $data_ref = $sth->fetchrow_hashref ()){
	#	print "$data_ref->{source_1}\n";

		my $sth = $global{dbh_jenz}->prepare (qq{
			select count(*) count 
			from candidate c, candidacy cd, name_master n
			left join address_master a on a.id_num = n.id_num and a.addr_cde = '*LHP'
			where
			n.id_num = cd.id_num and
			c.id_num = cd.id_num and
			cur_candidacy = 'Y' and
			yr_cde = '2011' and
			trm_cde = 'FA' and
			candidacy_type = 'F' and
			state = ? and
			right(stage, 3) >= '800'
			having count(*) > 0

				});
		$sth->execute ($data_ref->{state});
		if (my $enroll_ref = $sth->fetchrow_hashref ()){
			my $num = ($enroll_ref->{count} * $data_ref->{count} / 7699);
			my $decimal = ($num / $data_ref->{count});
			$num = sprintf("%.2f", $num);
			my $sth = $global{dbh_mysql}->prepare (qq{
				insert neural_menu set nm_type = 'F', nm_variable = 'state', nm_code = ?, nm_likelyhood = ?, nm_decimal = ?
					});
			$sth->execute ($data_ref->{state}, "$num/$data_ref->{count}", $decimal);
		} 
	}

	# Giving
	$sth = $global{dbh_jenz}->prepare (qq{
		select count(*) count from candidate c, candidacy cd, biograph_master b, candidate_udf udf
		where
		c.id_num = cd.id_num and
		c.id_num = b.id_num and
		c.id_num = udf.id_num and
		cur_candidacy = 'Y' and
		yr_cde = '2011' and
		trm_cde = 'FA' and
		--legacy = 'y' and
		candidacy_type = 'F' and
			exists (select family_id from relation_table rt, biograph_master b, DONOR_MASTER d
				where rt.id_num = c.id_num and
				b.id_num = rel_id_num and
				d.id_num = family_id and
				rel_cde = 'Parn' and
				cash_gift_num > 0
			)
		having count(*) > 0
			});
	$sth->execute ();
	while (my $data_ref = $sth->fetchrow_hashref ()){
		my $sth = $global{dbh_jenz}->prepare (qq{
			select count(*) count from candidate c, candidacy cd, biograph_master b, candidate_udf udf
			where
			c.id_num = cd.id_num and
			c.id_num = b.id_num and
			c.id_num = udf.id_num and
			cur_candidacy = 'Y' and
			yr_cde = '2011' and
			trm_cde = 'FA' and
			-- legacy = 'y' and
			candidacy_type = 'F' and
			right(stage, 3) >= '800' and
			exists (select family_id from relation_table rt, biograph_master b, DONOR_MASTER d
				where rt.id_num = c.id_num and
				b.id_num = rel_id_num and
				d.id_num = family_id and
				rel_cde = 'Parn' and
				cash_gift_num > 0
			)
			having count(*) > 0
				});
		$sth->execute ();
		if (my $enroll_ref = $sth->fetchrow_hashref ()){
			my $num = $enroll_ref->{count};
			my $decimal = ($num / $data_ref->{count});
			my $sth = $global{dbh_mysql}->prepare (qq{
				insert neural_menu set nm_type = 'F', nm_variable = 'giving', nm_code = '', nm_likelyhood = ?, nm_decimal = ?
					});
			$sth->execute ("$num/$data_ref->{count}", $decimal);
		} 
	}

	# legacy
	$sth = $global{dbh_jenz}->prepare (qq{
		select count(*) count from candidate c, candidacy cd, biograph_master b, candidate_udf udf
		where
		c.id_num = cd.id_num and
		c.id_num = b.id_num and
		c.id_num = udf.id_num and
		cur_candidacy = 'Y' and
		yr_cde = '2011' and
		trm_cde = 'FA' and
		legacy = 'y' and
		candidacy_type = 'F' 
		having count(*) > 0
			});
	$sth->execute ();
	while (my $data_ref = $sth->fetchrow_hashref ()){
		my $sth = $global{dbh_jenz}->prepare (qq{
			select count(*) count from candidate c, candidacy cd, biograph_master b, candidate_udf udf
			where
			c.id_num = cd.id_num and
			c.id_num = b.id_num and
			c.id_num = udf.id_num and
			cur_candidacy = 'Y' and
			yr_cde = '2011' and
			trm_cde = 'FA' and
			legacy = 'y' and
			candidacy_type = 'F' and
			right(stage, 3) >= '800'
			having count(*) > 0
				});
		$sth->execute ();
		if (my $enroll_ref = $sth->fetchrow_hashref ()){
			my $num = $enroll_ref->{count};
			my $decimal = ($num / $data_ref->{count});
			my $sth = $global{dbh_mysql}->prepare (qq{
				insert neural_menu set nm_type = 'F', nm_variable = 'legacy', nm_code = '', nm_likelyhood = ?, nm_decimal = ?
					});
			$sth->execute ("$num/$data_ref->{count}", $decimal);
		} 
	}

	# efc
	$sth = $global{dbh_jenz}->prepare (qq{
		select count(*) count from candidate c, candidacy cd, biograph_master b, candidate_udf udf
		where
		c.id_num = cd.id_num and
		c.id_num = b.id_num and
		c.id_num = udf.id_num and
		cur_candidacy = 'Y' and
		yr_cde = '2011' and
		trm_cde = 'FA' and
		efc like '11%' and
		candidacy_type = 'F'
		having count(*) > 0
			});
	$sth->execute ();
	while (my $data_ref = $sth->fetchrow_hashref ()){
		my $sth = $global{dbh_jenz}->prepare (qq{
			select count(*) count from candidate c, candidacy cd, biograph_master b, candidate_udf udf
			where
			c.id_num = cd.id_num and
			c.id_num = b.id_num and
			c.id_num = udf.id_num and
			cur_candidacy = 'Y' and
			yr_cde = '2011' and
			trm_cde = 'FA' and
			candidacy_type = 'F' and
			efc like '11%' and
			right(stage, 3) >= '800'
			having count(*) > 0
				});
		$sth->execute ();
		if (my $enroll_ref = $sth->fetchrow_hashref ()){
			my $num = $enroll_ref->{count};
			my $decimal = ($num / $data_ref->{count});
			$num = sprintf("%.2f", $num);
			my $sth = $global{dbh_mysql}->prepare (qq{
				insert neural_menu set nm_type = 'F', nm_variable = 'efc', nm_code = '', nm_likelyhood = ?, nm_decimal = ?
					});
			$sth->execute ("$num/$data_ref->{count}", $decimal);
		} 
	}

	# test score
	$sth = $global{dbh_jenz}->prepare (qq{
		select count(*) count from candidate c, candidacy cd
		where
		c.id_num = cd.id_num and
		cur_candidacy = 'Y' and
		yr_cde = '2011' and
		trm_cde = 'FA' and
		candidacy_type = 'F' and
		exists (select 1 from test_scores
			where
			id_num = c.id_num and
			tst_cde in ('act','sat') and
			self_reported = 'n'
		)
			});
	$sth->execute ();
	while (my $data_ref = $sth->fetchrow_hashref ()){
		my $num = 151;
		my $decimal = ($num / $data_ref->{count});
		$num = sprintf("%.2f", $num);
		my $sth = $global{dbh_mysql}->prepare (qq{
			insert neural_menu set nm_type = 'F', nm_variable = 'test_score', nm_code = '', nm_likelyhood = ?, nm_decimal = ?
				});
		$sth->execute ("$num/$data_ref->{count}", $decimal);
	}
	
	# current siblings
	$sth = $global{dbh_jenz}->prepare (qq{
		select count(*) count from candidate c, candidacy cd, biograph_master b, candidate_udf udf
		where
		c.id_num = cd.id_num and
		c.id_num = b.id_num and
		c.id_num = udf.id_num and
		cur_candidacy = 'Y' and
		yr_cde = '2011' and
		trm_cde = 'FA' and
		candidacy_type = 'F' and
		exists (SELECT UDEF_1A_4
			FROM STUDENT_MASTER s, RELATION_TABLE r
			WHERE 
			r.id_num = c.id_num and
			r.rel_id_num = s.id_num and
			REL_CDE = 'SIBL' and
			isnull(UDEF_1A_4,'ZZ') IN ('S','G','M')
		)
			});
	$sth->execute ();
	while (my $data_ref = $sth->fetchrow_hashref ()){
		my $sth = $global{dbh_jenz}->prepare (qq{
		select count(*) count from candidate c, candidacy cd, biograph_master b, candidate_udf udf
		where
		c.id_num = cd.id_num and
		c.id_num = b.id_num and
		c.id_num = udf.id_num and
		cur_candidacy = 'Y' and
		yr_cde = '2011' and
		trm_cde = 'FA' and
		candidacy_type = 'F' and
		exists (SELECT UDEF_1A_4
			FROM STUDENT_MASTER s, RELATION_TABLE r
			WHERE 
			r.id_num = c.id_num and
			r.rel_id_num = s.id_num and
			REL_CDE = 'SIBL' and
			isnull(UDEF_1A_4,'ZZ') IN ('S','G','M')
		) and
		right(stage, 3) >= '800'
				});
		$sth->execute ();
		if (my $enroll_ref = $sth->fetchrow_hashref ()){
			my $num = $enroll_ref->{count};
			my $decimal = ($num / $data_ref->{count});
			$num = sprintf("%.2f", $num);
			my $sth = $global{dbh_mysql}->prepare (qq{
				insert neural_menu set nm_type = 'F', nm_variable = 'current_sibling', nm_code = '', nm_likelyhood = ?, nm_decimal = ?
					});
			$sth->execute ("$num/$data_ref->{count}", $decimal);
		} 
	}

	# parent employee
	$sth = $global{dbh_jenz}->prepare (qq{
		select count(*) count from candidate c, candidacy cd, biograph_master b, candidate_udf udf
		where
		c.id_num = cd.id_num and
		c.id_num = b.id_num and
		c.id_num = udf.id_num and
		cur_candidacy = 'Y' and
		yr_cde = '2011' and
		trm_cde = 'FA' and
		candidacy_type = 'F' and
		exists (SELECT 'Yes' FROM biograph_master a
		        WHERE EMPLOYEE_OF_COLLEG = 'Y' and
		        (B.MOTHER_ID = A.ID_NUM or
			B.FATHER_ID = A.ID_NUM)
		)
			});
	$sth->execute ();
	while (my $data_ref = $sth->fetchrow_hashref ()){
		my $sth = $global{dbh_jenz}->prepare (qq{
		select count(*) count from candidate c, candidacy cd, biograph_master b, candidate_udf udf
		where
		c.id_num = cd.id_num and
		c.id_num = b.id_num and
		c.id_num = udf.id_num and
		cur_candidacy = 'Y' and
		yr_cde = '2011' and
		trm_cde = 'FA' and
		candidacy_type = 'F' and
		exists (SELECT 'Yes' FROM biograph_master a
		        WHERE EMPLOYEE_OF_COLLEG = 'Y' and
		        (B.MOTHER_ID = A.ID_NUM or
			B.FATHER_ID = A.ID_NUM)
		)  and
		right(stage, 3) >= '800'
				});
		$sth->execute ();
		if (my $enroll_ref = $sth->fetchrow_hashref ()){
			my $num = $enroll_ref->{count};
			my $decimal = ($num / $data_ref->{count});
			$num = sprintf("%.2f", $num);
			my $sth = $global{dbh_mysql}->prepare (qq{
				insert neural_menu set nm_type = 'F', nm_variable = 'faculty_kid', nm_code = '', nm_likelyhood = ?, nm_decimal = ?
					});
			$sth->execute ("$num/$data_ref->{count}", $decimal);
		} 
	}

	# Visits
	$sth = $global{dbh_jenz}->prepare (qq{
		select count(*) count from candidate c, candidacy cd, biograph_master b, candidate_udf udf
		where
		c.id_num = cd.id_num and
		c.id_num = b.id_num and
		c.id_num = udf.id_num and
		cur_candidacy = 'Y' and
		yr_cde = '2011' and
		trm_cde = 'FA' and
		candidacy_type = 'F' and
		exists (select 1 from gsc_items_ad_v
			where id_number = c.id_num and
			(action_code like 'AVE%' or 
			action_code like 'AVI%') and
			udef_3a_1 in ('CMP')
		)
			});
	$sth->execute ();
	while (my $data_ref = $sth->fetchrow_hashref ()){
		my $sth = $global{dbh_jenz}->prepare (qq{
		select count(*) count from candidate c, candidacy cd, biograph_master b, candidate_udf udf
		where
		c.id_num = cd.id_num and
		c.id_num = b.id_num and
		c.id_num = udf.id_num and
		cur_candidacy = 'Y' and
		yr_cde = '2011' and
		trm_cde = 'FA' and
		candidacy_type = 'F' and
		exists (select 1 from gsc_items_ad_v
			where id_number = c.id_num and
			(action_code like 'AVE%' or 
			action_code like 'AVI%') and
			udef_3a_1 in ('CMP')
		) and
		right(stage, 3) >= '800'
				});
		$sth->execute ();
		if (my $enroll_ref = $sth->fetchrow_hashref ()){
			my $num = $enroll_ref->{count};
			my $decimal = ($num / $data_ref->{count});
			$num = sprintf("%.2f", $num);
			my $sth = $global{dbh_mysql}->prepare (qq{
				insert neural_menu set nm_type = 'F', nm_variable = 'visits', nm_code = '', nm_likelyhood = ?, nm_decimal = ?
					});
			$sth->execute ("$num/$data_ref->{count}", $decimal);
		} 
	}
	# non Apps
#	$sth = $global{dbh_jenz}->prepare (qq{
#		select count(*) count from candidate c, candidacy cd
#		where
#		c.id_num = cd.id_num and
#		cur_candidacy = 'Y' and
#		yr_cde = '2011' and
#		trm_cde = 'FA' and
#		candidacy_type = 'F' and
#		(right(stage, 3) >= '400' or
#		source_1 in ('xawci','xawin') or
#		source_2 in ('xawci','xawin') or
#		source_3 in ('xawci','xawin') or
#		source_4 in ('xawci','xawin') or
#		source_5 in ('xawci','xawin') or
#		source_6 in ('xawci','xawin') or
#		source_7 in ('xawci','xawin') or
#		source_8 in ('xawci','xawin') or
#		source_9 in ('xawci','xawin') or
#		source_10 in ('xawci','xawin'))
#			});
#	$sth->execute ();
#	while (my $data_ref = $sth->fetchrow_hashref ()){
#		my $num = (151 * $data_ref->{count} / 7699);
#		$num = sprintf("%.2f", $num);
#		my $sth = $global{dbh_mysql}->prepare (qq{
#			insert neural_menu set nm_type = 'F', nm_variable = 'incomplete_apps', nm_code = '', nm_likelyhood = ?, nm_decimal = ?
#				});
#		$sth->execute ("$num/$data_ref->{count}");
#	}

	# Apps
#	$sth = $global{dbh_jenz}->prepare (qq{
#		select count(*) count from candidate c, candidacy cd
#		where
#		c.id_num = cd.id_num and
#		cur_candidacy = 'Y' and
#		yr_cde = '2011' and
#		trm_cde = 'FA' and
#		candidacy_type = 'F' and
#		right(stage, 3) >= '400'
#			});
#	$sth->execute ();
#	while (my $data_ref = $sth->fetchrow_hashref ()){
#		my $num = 151;
#		my $decimal = ($num / $data_ref->{count});
#		$num = sprintf("%.2f", $num);
#		my $sth = $global{dbh_mysql}->prepare (qq{
#			insert neural_menu set nm_type = 'F', nm_variable = 'apps', nm_code = '', nm_likelyhood = ?, nm_decimal = ?
#				});
#		$sth->execute ("$num/$data_ref->{count}", $decimal);
#	}
#	# Admits
#	$sth = $global{dbh_jenz}->prepare (qq{
#		select count(*) count from candidate c, candidacy cd
#		where
#		c.id_num = cd.id_num and
#		cur_candidacy = 'Y' and
#		yr_cde = '2011' and
#		trm_cde = 'FA' and
#		candidacy_type = 'F' and
#		right(stage, 3) >= '600'
#			});
#	$sth->execute ();
#	while (my $data_ref = $sth->fetchrow_hashref ()){
#		my $num = 151;
#		my $decimal = ($num / $data_ref->{count});
#		$num = sprintf("%.2f", $num);
#		my $sth = $global{dbh_mysql}->prepare (qq{
#			insert neural_menu set nm_type = 'F', nm_variable = 'admits', nm_code = '', nm_likelyhood = ?, nm_decimal = ?
#				});
#		$sth->execute ("$num/$data_ref->{count}", $decimal);
#	}
#	# Deposits
#	$sth = $global{dbh_jenz}->prepare (qq{
#		select count(*) count from candidate c, candidacy cd
#		where
#		c.id_num = cd.id_num and
#		cur_candidacy = 'Y' and
#		yr_cde = '2011' and
#		trm_cde = 'FA' and
#		candidacy_type = 'F' and
#		right(stage, 3) >= '700'
#			});
#	$sth->execute ();
#	while (my $data_ref = $sth->fetchrow_hashref ()){
#		my $num = 151;
#		my $decimal = ($num / $data_ref->{count});
#		$num = sprintf("%.2f", $num);
#		my $sth = $global{dbh_mysql}->prepare (qq{
#			insert neural_menu set nm_type = 'F', nm_variable = 'deposits', nm_code = '', nm_likelyhood = ?, nm_decimal = ?
#				});
#		$sth->execute ("$num/$data_ref->{count}", $decimal);
#	}

	# religion
#	$sth = $global{dbh_jenz}->prepare (qq{
#		select religion, count(*) count from candidate c, candidacy cd, biograph_master b
#		where
#		c.id_num = cd.id_num and
#		c.id_num = b.id_num and
#		cur_candidacy = 'Y' and
#		yr_cde = '2011' and
#		trm_cde = 'FA' and
#		candidacy_type = 'F' and
#		isnull(religion, '') <> ''
#		group by religion
#			});
#	$sth->execute ();
#	while (my $data_ref = $sth->fetchrow_hashref ()){
#	#	print "$data_ref->{source_1}\n";
#
#		my $sth = $global{dbh_jenz}->prepare (qq{
#			select count(*) count from candidate c, candidacy cd, biograph_master b
#			where
#			c.id_num = cd.id_num and
#			c.id_num = b.id_num and
#			cur_candidacy = 'Y' and
#			yr_cde = '2011' and
#			trm_cde = 'FA' and
#			candidacy_type = 'F' and
#			religion = ? and
#			right(stage, 3) >= '800'
#			having count(*) > 0
#				});
#		$sth->execute ($data_ref->{religion});
#		if (my $enroll_ref = $sth->fetchrow_hashref ()){
#			my $num = (($data_ref->{count} * $enroll_ref->{count}) / 151);
#			$num = sprintf("%.2f", $num);
#			my $sth = $global{dbh_mysql}->prepare (qq{
#				insert neural_menu set nm_type = 'F', nm_variable = 'religion', nm_code = ?, nm_likelyhood = ?
#					});
#			$sth->execute ($data_ref->{religion}, "$num/$data_ref->{count}");
#		} 
#	}
	my @variables = qw/source gender state/;
	foreach ('source','gender','state'){
		my @array;
		my $sth = $global{dbh_mysql}->prepare (qq{
			SELECT * FROM neural_menu
			where
			nm_variable = ?
				});
		$sth->execute ($_);
		while (my $data_ref = $sth->fetchrow_hashref ()){
			push @array, $data_ref->{nm_decimal};
		}
		my $ave = &average(\@array);
		my $std = &stdev(\@array);
	# 	print "$std\n";
		$sth = $global{dbh_mysql}->prepare (qq{
			SELECT * FROM neural_menu
			where
			nm_variable = ?
				});
		$sth->execute ($_);
		while (my $data_ref = $sth->fetchrow_hashref ()){
			my $weight = ($data_ref->{nm_decimal} - $ave) / $std;
			$weight = 1 if $weight > 1;
			my $sth = $global{dbh_mysql}->prepare (qq{
				update neural_menu set nm_stand_dev = ?
				where
				nm_variable = ? and
				nm_code = ?
					});
			$sth->execute ($weight, $_, $data_ref->{nm_code});
		#	print "$data_ref->{nm_variable} $data_ref->{nm_code} $data_ref->{nm_likelyhood} $weight\n";
		}
	}

	$sth = $global{dbh_mysql}->prepare (qq{
		SELECT * FROM neural_menu
		where
		nm_code = ''
			});
	$sth->execute ();
	while (my $data_ref = $sth->fetchrow_hashref ()){
		# print "$data_ref->{nm_variable}\n";
		my ($num, $denom) = return_fraction ($data_ref->{nm_decimal});
		my $weight = $num * 5 / $denom;
		my $sth = $global{dbh_mysql}->prepare (qq{
			update neural_menu set nm_stand_dev = ?
			where
			nm_variable = ?
				});
		$sth->execute ($weight, $data_ref->{nm_variable});
	}
}

sub tier_assignment {
	my (@valiable, %default, %default_value);
	open(OUT,">/home/amosmk/share/Summer Enrollment/tier.txt");
	my @out;
	my $sth = $global{dbh_mysql}->prepare (qq{
		SELECT * FROM neural_variable
			});
	$sth->execute ();
	while (my $var_ref = $sth->fetchrow_hashref ()){
		push @valiable, $var_ref->{n_variable};
		$default{$var_ref->{n_variable}} = $var_ref->{n_require_default};
		$default_value{$var_ref->{n_variable}} = $var_ref->{n_likelyhood_default};
	}
	my ($max, $min, $detail);
	local $^W; # turn off strict flag
	$sth = $global{dbh_jenz}->prepare (qq{
		select n.id_num, gender, source_1 source, state, legacy, efc, tier_override,
		(select top 1 '1a' from test_scores
				where
				id_num = n.id_num and
				tst_cde in ('act','sat') and
				self_reported = 'n'
		) test_score,
		(SELECT top 1 '1a'
				FROM STUDENT_MASTER s, RELATION_TABLE r
				WHERE 
				r.id_num = n.id_num and
				r.rel_id_num = s.id_num and
				REL_CDE = 'SIBL' and
				isnull(UDEF_1A_4,'ZZ') IN ('S','G','M')
		) current_sibling,
		(SELECT top 1 '1a' FROM biograph_master a
			        WHERE EMPLOYEE_OF_COLLEG = 'Y' and
			        (B.MOTHER_ID = A.ID_NUM or
				B.FATHER_ID = A.ID_NUM)
		) parent_employee,
		(select top 1 '1a' from gsc_items_ad_v
				where id_number = n.id_num and
				(action_code like 'AVE%' or 
				action_code like 'AVI%') and
				udef_3a_1 in ('CMP')
		) visited,
		case 
		when right(stage, 3) >= '400' then '1a'
		when source_1 in ('xawci','xawin') then '1a'
		when source_2 in ('xawci','xawin') then '1a'
		when source_3 in ('xawci','xawin') then '1a'
		when source_4 in ('xawci','xawin') then '1a'
		when source_5 in ('xawci','xawin') then '1a'
		when source_6 in ('xawci','xawin') then '1a'
		when source_7 in ('xawci','xawin') then '1a'
		when source_8 in ('xawci','xawin') then '1a'
		when source_9 in ('xawci','xawin') then '1a'
		when source_10 in ('xawci','xawin') then '1a'
		end incomplete_app,
		right(stage, 3) stage,
		religion
		from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = '*LHP',
		biograph_master b 
		left join candidacy cd on b.id_num = cd.id_num and CUR_CANDIDACY = 'Y'
		left join candidate c on cd.id_num = c.id_num
		left join candidate_udf u on c.id_num = u.id_num
		where
		n.id_num = b.id_num and
		yr_cde in ('2013','2014') and
		trm_cde = 'FA' and
		-- right(stage, 3) not like '_9%' and
		candidacy_type = 'F'
		-- and n.id_num = '133415'
			});
	$sth->execute ();
	while (my $contact_ref = $sth->fetchrow_hashref ()){
		my ($std, $count); 
		$detail = '';
		foreach my $var (@valiable){
#			if ($var eq 'apps'){
#				if ($contact_ref->{stage} >= '700'){
#					my $sth = $global{dbh_mysql}->prepare (qq{
#						SELECT * FROM neural_menu
#						where
#						nm_variable = ?
#							});
#					$sth->execute ('deposits');
#					if (my $menu_ref = $sth->fetchrow_hashref ()){
#						$std += $menu_ref->{nm_stand_dev};
#						$count++;
#					}
#				} elsif ($contact_ref->{stage} >= '600'){
#					my $sth = $global{dbh_mysql}->prepare (qq{
#						SELECT * FROM neural_menu
#						where
#						nm_variable = ?
#							});
#					$sth->execute ('admits');
#					if (my $menu_ref = $sth->fetchrow_hashref ()){
#						$std += $menu_ref->{nm_stand_dev};
#						$count++;
#					}
#				} elsif ($contact_ref->{stage} >= '400'){
#					my $sth = $global{dbh_mysql}->prepare (qq{
#						SELECT * FROM neural_menu
#						where
#						nm_variable = ?
#							});
#					$sth->execute ('apps');
#					if (my $menu_ref = $sth->fetchrow_hashref ()){
#						$std += $menu_ref->{nm_stand_dev};
#						$count++;
#					}
#				}
			if ($contact_ref->{$var} eq '1a'){
				my $sth = $global{dbh_mysql}->prepare (qq{
					SELECT * FROM neural_menu
					where
					nm_variable = ?
						});
				$sth->execute ($var);
				if (my $menu_ref = $sth->fetchrow_hashref ()){
						$std += $menu_ref->{nm_stand_dev};
						$count++;
						my $num = sprintf("%.2f", $menu_ref->{nm_stand_dev});
						$detail .= "$var ($num)";
				} else {
					print "$var not found\n";
				}
			} elsif ($contact_ref->{$var}){
				if ($var =~ /state|gender|source/){
					my $sth = $global{dbh_mysql}->prepare (qq{
						SELECT * FROM neural_menu
						where
						nm_variable = ? and
						nm_code = ?
							});
					$sth->execute ($var, $contact_ref->{$var});
					if (my $menu_ref = $sth->fetchrow_hashref ()){
						$std += $menu_ref->{nm_stand_dev};
						$count++;
						my $num = sprintf("%.2f", $menu_ref->{nm_stand_dev});
						$detail .= ", $var ($num)";
					} elsif ($default{$var}){
						$std += $default_value{$var};
						$count++;
						my $num = sprintf("%.2f", $default_value{$var});
						$detail .= ", $var ($num)";
					}
				} else {
					my $sth = $global{dbh_mysql}->prepare (qq{
						SELECT * FROM neural_menu
						where
						nm_variable = ?
							});
					$sth->execute ($var);
					if (my $menu_ref = $sth->fetchrow_hashref ()){
						$std += $menu_ref->{nm_stand_dev};
						$count++;
						my $num = sprintf("%.2f", $menu_ref->{nm_stand_dev});
						$detail .= ", $var ($num)";
					} else {
						print "$var not found\n";
					}
				}
			} elsif ($default{$var}){ # value that needs a fraction
				$std += $default_value{$var};
				$count++;
				my $num = sprintf("%.2f", $default_value{$var});
				$detail .= ", $var ($num)";
			}
		}
#		my $denom;
#		foreach (@valiable){
#			if ($frac{$_}){
#				$frac{$_} =~ /(.*)\/(.*)/;
#				if ($denom){
#					$denom = ($denom * $2);
#				} else {
#					$denom = $2;
#				}
#				print "$_ $frac{$_} - $1 - $2\n";
#			}
#		}
#		my ($newtotalnum, $newtotaldenom);
#		foreach (@valiable){
#			if ($frac{$_}){
#				$frac{$_} =~ /(.*)\/(.*)/;
#				my $new_numerator = ($denom * $1 / $2);
#				$newtotalnum += $new_numerator;
#				$newtotaldenom += $denom;
#			}
#		}
#		my $percent = ($newtotalnum / $newtotaldenom);
	#	print "$contact_ref->{id_num}\n";
	#	exit if $percent > '.44';
	#	print "$count\n";
		my $answer = $std / $count;
		push @out, "$contact_ref->{id_num}\t$contact_ref->{stage}\t$answer\n";
		$contact_ref->{tier_override} = '' if $contact_ref->{tier_override} eq ' ';
		next if $contact_ref->{tier_override};
		if ($answer >= .5){
			my $sth = $global{dbh_jenz}->prepare (qq{
				update candidate_udf set tier = 'Tier 1', tier_details = "$detail"
				where
				id_num = ?
					});
			$sth->execute ($contact_ref->{id_num});
		} elsif ($answer >= .33){
			my $sth = $global{dbh_jenz}->prepare (qq{
				update candidate_udf set tier = 'Tier 2', tier_details = "$detail"
				where
				id_num = ?
					});
			$sth->execute ($contact_ref->{id_num});
		} else {
			my $sth = $global{dbh_jenz}->prepare (qq{
				update candidate_udf set tier = 'Tier 3', tier_details = "$detail"
				where
				id_num = ?
					});
			$sth->execute ($contact_ref->{id_num});
		}
#		print "$detail\n";

	#	$max = $answer if $answer > $max || !$max;
	#	$min = $answer if $answer < $min || !$min;
	#	exit if $max > 1.4040;
	}
	#print OUT @out;
	#print "$max\n";
	#print "$min\n";
}

sub populate_demographics {
	my $sth = $global{dbh_mysql_admission}->prepare (qq{
		delete FROM sources
		where
		skey2 >= '2012'
			});
	$sth->execute ();

	local $^W; # turn off strict flag
	$sth = $global{dbh_jenz}->prepare (qq{
		select n.id_num, gender, state, city, yr_cde, trm_cde, legacy, efc, tier_override, lead, tier,
		convert(varchar(12), c.udef_dte_2, 112) createon,
		right(stage, 3) stage,
		case candidacy_type
		when 'F' then 'FF'
		when 'I' then 'IF'
		when 'J' then 'IT'
		when 'K' then 'IR'
		when 'P' then 'PG'
		when 'R' then 'RA'
		when 'X' then 'TS'
		when 'T' then 'TR' end type,
		source_1, load_p_f, religion, state,
		(select top 1 county_name from gsc_citycounty
			where
			county = a.county) county,
		(select isnull(last_name, '')+isnull(first_name, '') from name_master
		where
		id_num = (
			select org_id__ad from ad_org_tracking
			where
			id_num = n.id_num and
			org_type_ad_ = 'HS' and
			last_high_school = 'Y'
			)
		) as high_school,
		(select isnull(last_name, '')+isnull(first_name, '') from name_master
		where
		id_num = (
			select id_num from org_master 
			where
			org_type = 'ch' and
			org_cde = b.udef_5a_1
			)
		) as church,
		case
		when source_1 in ('xpapp','xwcap','xwaap') then source_1
		when source_2 in ('xpapp','xwcap','xwaap') then source_2
		when source_3 in ('xpapp','xwcap','xwaap') then source_3
		when source_4 in ('xpapp','xwcap','xwaap') then source_4
		when source_5 in ('xpapp','xwcap','xwaap') then source_5
		when source_6 in ('xpapp','xwcap','xwaap') then source_6
		when source_7 in ('xpapp','xwcap','xwaap') then source_7
		when source_8 in ('xpapp','xwcap','xwaap') then source_8
		when source_9 in ('xpapp','xwcap','xwaap') then source_9
		when source_10 in ('xpapp','xwcap','xwaap') then source_10
		end app,
		source_2,
		source_3,
		source_4,
		source_5,
		source_6,
		source_7,
		source_8,
		source_9,
		source_10,
		(select counselor_title from counselor_responsi
			where
			counselor_initials = c.counselor_initials) counselor,
		coalesce(dbo.race_ethnicity(n.id_num),
		            dbo.detail(ethnic_group, 'ethnic_group', default, default), 'None reported') ethnicity
 
		/* (select top 1 '1a' from test_scores
				where
				id_num = n.id_num and
				tst_cde in ('act','sat') and
				self_reported = 'n'
		) test_score,
		(SELECT top 1 '1a'
				FROM STUDENT_MASTER s, RELATION_TABLE r
				WHERE 
				r.id_num = n.id_num and
				r.rel_id_num = s.id_num and
				REL_CDE = 'SIBL' and
				isnull(UDEF_1A_4,'ZZ') IN ('S','G','M')
		) current_sibling,
		(SELECT top 1 '1a' FROM biograph_master a
			        WHERE EMPLOYEE_OF_COLLEG = 'Y' and
			        (B.MOTHER_ID = A.ID_NUM or
				B.FATHER_ID = A.ID_NUM)
		) parent_employee,
		(select top 1 '1a' from gsc_items_ad_v
				where id_number = n.id_num and
				(action_code like 'AVE%' or 
				action_code like 'AVI%') and
				udef_3a_1 in ('CMP')
		) visited,
		case 
		when right(stage, 3) >= '400' then '1a'
		when source_1 in ('xawci','xawin') then '1a'
		when source_2 in ('xawci','xawin') then '1a'
		when source_3 in ('xawci','xawin') then '1a'
		when source_4 in ('xawci','xawin') then '1a'
		when source_5 in ('xawci','xawin') then '1a'
		when source_6 in ('xawci','xawin') then '1a'
		when source_7 in ('xawci','xawin') then '1a'
		when source_8 in ('xawci','xawin') then '1a'
		when source_9 in ('xawci','xawin') then '1a'
		when source_10 in ('xawci','xawin') then '1a'
		end incomplete_app,
		religion */
		from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = '*LHP',
		biograph_master b 
		left join candidacy cd on b.id_num = cd.id_num and CUR_CANDIDACY = 'Y'
		left join candidate c on cd.id_num = c.id_num
		left join candidate_udf u on c.id_num = u.id_num
		where
		n.id_num = b.id_num and
		yr_cde in ('2012','2013','2014') and
		-- yr_cde in ('2012') and
		trm_cde in ('FA','sp','ma','su') and
		isnull(name_sts, '') <> 'D' and
		isnull(dept_cde, '') <> 'GAP' and
		cd.prog_cde not in ('46','460') and -- not TtT
		-- right(stage, 3) not like '_9%' and
		candidacy_type in ('F','T','i','j','k','r','p','x');
		-- and n.id_num = '133415'
			});
	$sth->execute ();
	while (my $contact_ref = $sth->fetchrow_hashref ()){
		m_strip_space ($contact_ref, $sth->{NAME});
		$contact_ref->{stage} =~ s/(..)./$1/;
		$contact_ref->{stage} =~ s/^0//;
		# print "$contact_ref->{stage}\n";
		$contact_ref->{app} =~ s/xpapp/XAPP/i;
		$contact_ref->{app} =~ s/xwaap/XWAPP/i;
		if ($contact_ref->{ethnicity} =~ s/Black or African American/B/){
		} elsif ($contact_ref->{ethnicity} =~ s/Hispanic or Latino/H/){
		} elsif ($contact_ref->{ethnicity} =~ /Far East/i){
			$contact_ref->{ethnicity} = 'A';
		} elsif ($contact_ref->{ethnicity} =~ s/Asian/A/){
		} elsif ($contact_ref->{ethnicity} =~ s/American Indian or Alaska Native/I/){
		} elsif ($contact_ref->{ethnicity} =~ s/Native Hawaiian or Other Pacific Islander/P/){
		} elsif ($contact_ref->{ethnicity} =~ s/Hispanics of any race/H/){
		} elsif ($contact_ref->{ethnicity} =~ s/Two or more races/M/){
		} elsif ($contact_ref->{ethnicity} =~ s/White/W/){
		} elsif ($contact_ref->{ethnicity} =~ s/Reported//){
		} else {
			$contact_ref->{ethnicity} = 'X'; # 'BL'
		}
		# print "'$contact_ref->{ethnicity}'\n" if $contact_ref->{ethnicity};
		$contact_ref->{church} =~ s/ *$//;
		$contact_ref->{high_school} =~ s/ *$//;
		$contact_ref->{church} .= " - $contact_ref->{state}" if $contact_ref->{church};
		$contact_ref->{high_school} .= " - $contact_ref->{state}" if $contact_ref->{high_school};

		# print "$contact_ref->{yr_cde} $contact_ref->{trm_cde}\n";
			my $sth = $global{dbh_mysql_admission}->prepare (qq{
				insert sources set skey1 = ?, skey2 = ?, skey3 = ?, sfirst_source = ?, sfullpart = ?, sdenom = ?, scounselor = ?, sstate = ?, scounty = ?, shighschool = ?, sgender = ?, scity = ?, schurch = ?, sapp = ?, sethnic = ?, slead = ?, screateon = ?, sritier = ?
					});
			$sth->execute ($contact_ref->{stage}, "$contact_ref->{yr_cde} $contact_ref->{trm_cde}", $contact_ref->{type}, $contact_ref->{source_1}, $contact_ref->{load_p_f}, $contact_ref->{religion}, $contact_ref->{counselor}, $contact_ref->{state}, $contact_ref->{county}, $contact_ref->{high_school}, $contact_ref->{gender}, $contact_ref->{city}, $contact_ref->{church}, $contact_ref->{app}, $contact_ref->{ethnicity}, $contact_ref->{lead}, $contact_ref->{createon}, $contact_ref->{tier});
		
		foreach ('source_1','source_2','source_3','source_4','source_5','source_6','source_7','source_8','source_9','source_10'){
			last unless $contact_ref->{$_};
			my $sth = $global{dbh_mysql_admission}->prepare (qq{
				insert sources set skey1 = ?, skey2 = ?, skey3 = ?, ssource = ?, sfullpart = ?, sdenom = ?, scounselor = ?, sstate = ?, scounty = ?, shighschool = ?, sgender = ?, scity = ?, schurch = ?, sapp = ?, sethnic = ?, slead = ?, screateon = ?, sritier = ?
					});
			$sth->execute ($contact_ref->{stage}, "$contact_ref->{yr_cde} $contact_ref->{trm_cde}", $contact_ref->{type}, $contact_ref->{$_}, $contact_ref->{load_p_f}, $contact_ref->{religion}, $contact_ref->{counselor}, $contact_ref->{state}, $contact_ref->{county}, $contact_ref->{high_school}, $contact_ref->{gender}, $contact_ref->{city}, $contact_ref->{church}, $contact_ref->{app}, $contact_ref->{ethnicity}, $contact_ref->{lead}, $contact_ref->{createon}, $contact_ref->{tier});
		}
	}
}

sub average {
        my ($data) = @_;
        if (not @$data) {
		return;
#                die("Empty array\n");
        }
        my $total = 0;
        foreach (@$data) {
                $total += $_;
        }
        my $average = $total / @$data;
        return $average;
}
sub stdev{
        my($data) = @_;
        if(@$data == 1){
                return 0;
        }
        my $average = &average($data);
        my $sqtotal = 0;
        foreach(@$data) {
                $sqtotal += ($average-$_) ** 2;
        }
        my $std = ($sqtotal / (@$data-1)) ** 0.5;
        return $std;
}

sub return_fraction {
	my $x = shift;
	my ($int, $frac) = split( /\./, $x );

	my $num = $frac;
	my $denom = $frac;
	$denom =~ s/\d/0/g;
	$denom = "1$denom";

	return ($num, $denom);
}

sub snap_shot {
	my (%type, %term, %fullpart, %hstype, $flag);
	$type{FF} = 'first-year';
	$type{TR} = 'transfer';
	$term{FA} = 'fall';
	$term{SP} = 'spring';
	$term{MA} = 'May-Term';
	$term{SU} = 'summer';
	$fullpart{F} = 'Full Time enrollment';
	$fullpart{P} = 'Part Time enrollment';
	$fullpart{'P1-5'} = 'Part Time 1-5 Hours';
	$fullpart{'P6-11'} = 'Part Time 6-11 Hours';
	$hstype{F} = 'Final';
	$hstype{O} = 'Official';
	$hstype{S} = 'Self-reported';
	$hstype{SP} = 'Partial';
	$hstype{ST} = 'Test';
	$hstype{U} = 'Unofficial';

	my ($count, %header, %requirements, @headers, $select, @problems, @rows, @cover_sheet, @update, @calls, @column_list, $overall_update_flag);

	my (@year);
	@year = ('2011');

	my %translation = ('ucounty','County','key5','ID','unamelast','Last','unamefirst','First','dear','Dear','unamemid','Middle','key2','Term','department','Add_type','ubirthdate','Birthday','ufullpart','Full/Part','ugender','Gender','u_email','GC_Email','company','SSN');

	local $^W; # turn off strict flag

	foreach my $year (@year){
		@cover_sheet = ();
		my @column = qw/
		*id_num
		first_name
		last_name
		preferred_name
		tier
		*Source
		*Source_des
		middle_name	
		*Status
		*Status_des
		*App_binary
		*Admit_binary
		*Deposit_binary
		*Enroll_binary
		*Individual_visit
		*COH_visit
		*first_COH
		*first_visit
		*Type
		*Type_des
		yr_cde
		addr_line_1-Address1
		addr_line_2-Address2
		City
		State
		Zip
		Country
		County
		*Fullpart
		gender
		birth_dte-Birth_Date
		*ethnicity
		*ethnicity_des
		marital_sts
		*CITL_Status
		*Academic_Level
		lead-Lead_Category
		housing_cde
		counselor_initials
		*ACT
		*SAT
		*SAT_type
		*GPA
		*GPA_type
		*High_School
		*HS_CEEB
		*Church
		*Church_CEEB
		religion
		*App_date
		*App_fee
		*ACT_SAT_Date
		fafsa_file_date-FAFSA_Filed_Date
		efc-FAFSA_EFC
		*FA_Award_Date
		*21st_Century
		*National_Merit
		*Academic_Sch
		*Stoltzfus
		*File_Complete_Date
		*Deposit_Date
		*Register_Date
		*Housing_Date
		*Predicted_GPA
		prog_cde-Major
		second_program_of_interest-Major2
		third_program_of_interest-Major3
		legacy-Legacy
		/;

		my ($string);
		foreach (@column){
			my @split = split(/-/);
			my $name = $split[0];
			unless ($name =~ s/^\*//){
				if ($split[1] =~ /Date/){
					$string .= "convert(varchar(12), $name, 101) as $name, ";
				} else {
					$string .= "$name, ";
				}
			}
			if ($translation{$name}){
				push @cover_sheet, "$translation{$name}\t";
			} elsif ($split[1]){
				push @cover_sheet, "$split[1]\t";
			} else {
				push @cover_sheet, "$name\t";
			}
		}
		# print "$string\n";
		$cover_sheet[-1] =~ s/\t/\n/;
		my $sth = $global{dbh_jenz}->prepare (qq{
			select n.id_num, convert(varchar(12), getdate(), 101) as date, $string
			source_1, source_1 Source, stage, right(stage, 3) Status, candidacy_type Type, candidacy_type,
			case when c.udef_3a_4 = 'Yes' then 'P 1-5'
				else load_p_f
				end Fullpart,
			b.udef_1a_6 Academic_Level,
			convert(varchar(12), c.udef_dte_1, 101) FA_Award_Date,
			c.udef_1a_9 '21st_Century',
			c.udef_2a_2 National_Merit,
			c.udef_2a_4 Academic_Sch,
			c.udef_dte_6 Housing_Date,
			case
			when (select ipeds_report_value from gsc_cm_ethnic_race_view where id_num = n.id_num) = 1 then 9
			when (select ipeds_report_value from gsc_cm_ethnic_race_view where id_num = n.id_num) = 3 then 4
			when (select ipeds_report_value from gsc_cm_ethnic_race_view where id_num = n.id_num) = 4 then 1
			when (select ipeds_report_value from gsc_cm_ethnic_race_view where id_num = n.id_num) = 5 then 2
			when (select ipeds_report_value from gsc_cm_ethnic_race_view where id_num = n.id_num) = 6 then 3
			when (select ipeds_report_value from gsc_cm_ethnic_race_view where id_num = n.id_num) = 8 then 6
			else ethnic_group end ethnicity,
			case
			when (select ipeds_race_ethnicity from gsc_cm_ethnic_race_view where id_num = n.id_num) is not null then (select ipeds_race_ethnicity from gsc_cm_ethnic_race_view where id_num = n.id_num)
			when ethnic_group = 1 then 'American Indian or Alaska Native'
			when ethnic_group = 2 then 'Asian'
			when ethnic_group = 3 then 'Black or African American'
			when ethnic_group = 4 then 'Hispanics of any race'
			when ethnic_group = 6 then 'White'
			when ethnic_group = 8 then 'Other'
			when ethnic_group = 9 then 'Nonresident Alien'
			end ethnicity_des,
			( select top 1 convert(varchar(12), hist_stage_dte, 101)
				from stage_history_tran s
				where 
				id_num = n.id_num and
				substring(hist_stage, 2, 3) >= '475' and
				-- substring(hist_stage, 2, 3) like '_9_' and
				yr_cde = cd.yr_cde and
				trm_cde = cd.trm_cde
				order by hist_stage
			) File_Complete_Date,
			( select top 1 convert(varchar(12), hist_stage_dte, 101)
				from stage_history_tran s
				where 
				id_num = n.id_num and
				substring(hist_stage, 2, 3) >= '700' and
				-- substring(hist_stage, 2, 3) like '_9_' and
				yr_cde = cd.yr_cde and
				trm_cde = cd.trm_cde
				order by hist_stage
			) Deposit_Date,
			( select top 1 convert(varchar(12), hist_stage_dte, 101)
				from stage_history_tran s
				where 
				id_num = n.id_num and
				substring(hist_stage, 2, 3) >= '720' and
				-- substring(hist_stage, 2, 3) like '_9_' and
				yr_cde = cd.yr_cde and
				trm_cde = cd.trm_cde
				order by hist_stage
			) Register_Date,
			(select top 1 'Y' from ad_scholarship
				where
				id_num = n.id_num and
				yr_cde = cd.yr_cde and
				trm_cde = cd.trm_cde and
				transferred_to_pf = 'y' and
				scholarship_type = 'pla'
			) National_Merit, 
			(select top 1 'Y' from ad_scholarship
				where
				id_num = n.id_num and
				yr_cde = cd.yr_cde and
				trm_cde = cd.trm_cde and
				transferred_to_pf = 'y' and
				scholarship_type = 'stoltz'
			) Stoltzfus,
			( select top 1 
				case when COMPLETION_STS = 'I' then 'Needed'
					when COMPLETION_STS = 'C' then convert(varchar(12), completion_dte_dte, 101)
					 end
				from requirements
				where
				id_num = n.id_num and
				req_cde = 'appdt' and
				yr_cde = cur_yr and
				trm_cde = cur_trm
			) App_date,
			( select top 1 
				case when COMPLETION_STS = 'I' then 'Needed'
					when COMPLETION_STS = 'C' then convert(varchar(12), completion_dte_dte, 101)
					 end
				from requirements
				where
				id_num = n.id_num and
				req_cde = 'AAFEE' and
				yr_cde = cur_yr and
				trm_cde = cur_trm
			) App_fee,
			(select 'Y' from ad_scholarship
				where
				id_num = n.id_num and
				yr_cde = cd.yr_cde and
				trm_cde = cd.trm_cde and
				date_scholarship_accepted is not null and
				scholarship_type = 'citl'
			) CITL_Status,
			( select top 1 
				case when COMPLETION_STS = 'I' then ''
					when COMPLETION_STS = 'C' then convert(varchar(12), completion_dte_dte, 101)
					 end
				from requirements
				where
				id_num = n.id_num and
				req_cde = 'aacsa' and
				yr_cde = cur_yr and
				trm_cde = cur_trm
			) test_date,
			(select top 1 1
				from gsc_items_ad_v
				where id_number = n.id_num and
				(action_code like 'avi%') and
				udef_3a_1 in ('CMP')
			) Individual_visit,
			(select top 1 1
				from gsc_items_ad_v
				where id_number = n.id_num and
				(action_code like 'ave%') and
				udef_3a_1 in ('CMP')
			) COH_visit,
			(select top 1 convert(varchar(12), item_date, 101)
				from gsc_items_ad_v
				where id_number = n.id_num and
				(action_code like 'ave%') and
				udef_3a_1 in ('CMP')
				order by item_date
			) first_COH,
			(select top 1 convert(varchar(12), item_date, 101)
				from gsc_items_ad_v
				where id_number = n.id_num and
				(action_code like 'avi%') and
				udef_3a_1 in ('CMP')
				order by item_date
			) first_visit,
			(cast(round (
			((select max(tst_score)
					from test_scores_detail
					where 
					id_num = n.id_num and 
					tst_cde = 'ACT' and
					tst_elem = 'acten' and
					exists ( select 1 from test_scores
						where
						id_num = test_scores_detail.id_num and
						self_reported = 'n'
					)
			) +
			(select max(tst_score)
					from test_scores_detail
					where 
					id_num = n.id_num and 
					tst_cde = 'ACT' and
					tst_elem = 'actrd' and
					exists ( select 1 from test_scores
						where
						id_num = test_scores_detail.id_num and
						self_reported = 'n'
					)
			) +
			(select max(tst_score)
					from test_scores_detail
					where 
					id_num = n.id_num and 
					tst_cde = 'ACT' and
					tst_elem = 'actmt' and
					exists ( select 1 from test_scores
						where
						id_num = test_scores_detail.id_num and
						self_reported = 'n'
					)
			) +
			(select max(tst_score)
					from test_scores_detail
					where 
					id_num = n.id_num and 
					tst_cde = 'ACT' and
					tst_elem = 'actsc' and
					exists ( select 1 from test_scores
						where
						id_num = test_scores_detail.id_num and
						self_reported = 'n'
					)
			)) / 4, 2,0) as decimal(10,0))) as ACT, 
		cast(round ( 
		(select max(tst_score) 
			from test_scores_detail
			where 
			id_num = n.id_num and 
			tst_cde = 'SAT' and
			tst_elem = 'satv' and
			exists ( select 1 from test_scores
				where
				id_num = test_scores_detail.id_num and
				self_reported = 'n'
			)
		) +
		(select max(tst_score) 
			from test_scores_detail
			where 
			id_num = n.id_num and 
			tst_cde = 'SAT' and
			tst_elem = 'satm' and
			exists ( select 1 from test_scores
				where
				id_num = test_scores_detail.id_num and
				self_reported = 'n'
			)
		),2,0) as decimal(10,0)) SAT_type,
		(select cast(round (gpa, 2,0) as decimal(10,2))
			from ad_org_tracking
			where
			id_num = n.id_num and
			last_high_school = 'Y' and
			org_type_ad_ = 'HS'	
		) GPA, 
		(select cast(round (self_reported_gpa, 2,0) as decimal(10,2))
			from ad_org_tracking
			where
			id_num = n.id_num and
			last_high_school = 'Y' and
			org_type_ad_ = 'HS'	
		) Predicted_GPA, 
		 (	select case udef_2a_1
		when 'F' then 'Final'
		when 'G' then 'On file with Registrar'
		when 'N' then 'Not needed (PG)'
		when 'O' then 'Official'
		when 'P' then 'Partial'
		when 'S' then 'Self-reported'
		when 'U' then 'Unofficial'
		end
		from ad_org_tracking
		where
		id_num = n.id_num and
		last_high_school = 'Y' and
		org_type_ad_ = 'HS'	
		) GPA_type,
		(	select (select isnull(last_name, '')+isnull(first_name, '') from name_master 
			where
			id_num = org_id__ad and
			name_format = 'B'
			) 
		from ad_org_tracking
		where
		id_num = n.id_num and
		last_high_school = 'Y' and
		org_type_ad_ = 'HS'	
		) High_School,
		(select org_cde_ad
		from ad_org_tracking
		where
		id_num = n.id_num and
		last_high_school = 'Y' and
		org_type_ad_ = 'HS'	
		) HS_CEEB,
		b.udef_5a_1 Church_CEEB, 
		(select isnull(last_name, '')+isnull(first_name, '') from name_master
		where
		id_num = (
			select id_num from org_master 
			where
			org_type = 'ch' and
			org_cde = b.udef_5a_1
			)
		) as church
		from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = '*LHP',
		biograph_master b 
		left join candidacy cd on b.id_num = cd.id_num and CUR_CANDIDACY = 'Y'
		left join candidate c on cd.id_num = c.id_num
		left join candidate_udf u on c.id_num = u.id_num
		where
		n.id_num = b.id_num and
		yr_cde = ? and
		trm_cde = 'FA'
				});
		$sth->execute ($year);
		while (my $contact_ref = $sth->fetchrow_hashref ()){
			my (%ap, $ap_counter, @problem_list, $update_flag, @update_store, $not_logged_in_oracle);
			$flag++;
			foreach (@column){
				my @split = split(/-/);
				my $name = $split[0];
				$name =~ s/^\*//;
				#if ($name eq 'FullPart_des'){
				#	push @cover_sheet, "$fullpart{$contact_ref->{ufullpart}}\t";
				if ($name eq 'App_binary'){
					if ($contact_ref->{Status} >= 400){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'Admit_binary'){
					if ($contact_ref->{Status} >= 600){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'Deposit_binary'){
					if ($contact_ref->{Status} >= 700){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'Enroll_binary'){
					if ($contact_ref->{Status} >= 800){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'Legacy'){
					if ($contact_ref->{legacy} =~ /Y/i){
						push @cover_sheet, "1\t";
					} else {
						push @cover_sheet, "0\t";
					}
				} elsif ($name eq 'Status_des'){
					my $sth = $global{dbh_mysql}->prepare (qq{
						SELECT il_description from import_lookup
						where
						il_column = 'cur_stage' and
						il_code = ?
							});
					$sth->execute ($contact_ref->{stage});
					if (my $lookup_ref = $sth->fetchrow_hashref ()){
						push @cover_sheet, "$lookup_ref->{il_description}\t";
					} else {
						push @cover_sheet, "\t";
					}
				} elsif ($name eq 'Type_des'){
					my $sth = $global{dbh_mysql}->prepare (qq{
						SELECT il_description from import_lookup
						where
						il_column = 'type' and
						il_code = ?
							});
					$sth->execute ($contact_ref->{candidacy_type});
					if (my $lookup_ref = $sth->fetchrow_hashref ()){
						push @cover_sheet, "$lookup_ref->{il_description}\t";
					} else {
						push @cover_sheet, "\t";
					}
				} elsif ($name eq 'Source_des'){
					my $sth = $global{dbh_mysql}->prepare (qq{
						SELECT il_description from import_lookup
						where
						il_column = 'source' and
						il_code = ?
							});
					$sth->execute ($contact_ref->{source_1});
					if (my $lookup_ref = $sth->fetchrow_hashref ()){
						push @cover_sheet, "$lookup_ref->{il_description}\t";
					} else {
						push @cover_sheet, "\t";
					}
				} else {
					if ($contact_ref->{$name}){
						push @cover_sheet, "$contact_ref->{$name}\t";
					} else {
						push @cover_sheet, "\t";
					}
				}
			}
			$cover_sheet[-1] =~ s/\t/\n/;
		}
		open(OUT,">$global{g_path}reports/snapshot/list.txt");
		print OUT @cover_sheet;
		close (OUT);
	}
}

sub sibling_off_app {
	push my @list, "id_num\tfirst\tmiddle\tlast\tsuffx\tyear\tterm\taddr1\taddr2\tcity\tstate\tzip\tcountry\ths_ceeb\treligion\tchruch_ceeb\n";
	my $sth = $global{dbh_jenz}->prepare (qq{
		select n.id_num, last_name, oaa_sibling_name_1, oaa_sibling_gradyear_1,
		oaa_sibling_name_2, oaa_sibling_gradyear_2,
		oaa_sibling_name_3, oaa_sibling_gradyear_3,
		oaa_sibling_name_4, oaa_sibling_gradyear_4,
		addr_line_1, addr_line_2, city, state, zip,
		( 	select table_desc from table_detail
			where
			table_value = country and
			column_name = 'country' 
		) country,
		(	select (select isnull(last_name, '')+isnull(first_name, '') from name_master 
				where
				id_num = org_id__ad and
				name_format = 'B'
				) 
			from ad_org_tracking
			where
			id_num = n.id_num and
			last_high_school = 'Y' and
			org_type_ad_ = 'HS'	
		) hs_name,
		(	select org_cde_ad
			from ad_org_tracking
			where
			id_num = n.id_num and
			last_high_school = 'Y' and
			org_type_ad_ = 'HS'	
		) hs_ceeb,
		(select isnull(last_name, '')+isnull(first_name, '') from name_master
		where
		id_num = (
			select id_num from org_master 
			where
			org_type = 'ch' and
			org_cde = b.udef_5a_1
			)
		) as church,
		b.udef_5a_1 church_ceeb,
		religion religion_code,
		( 	select table_desc from table_detail
				where
				table_value = religion and
				column_name = 'religion' 
		) religion
		from name_master n left join address_master a on a.id_num = n.id_num and a.addr_cde = '*LHP',
		biograph_master b 
		left join candidacy cd on b.id_num = cd.id_num and CUR_CANDIDACY = 'Y'
		left join candidate c on cd.id_num = c.id_num
		left join candidate_udf u on c.id_num = u.id_num
		where
		n.id_num = b.id_num and
		yr_cde >= '2012' and
		isnull(oaa_sibling_name_1, '') <> '' and
		candidacy_type in ('F','T') and
		isnull(siblings_exported, '') = '' and
		isnull(name_sts, '') <> 'D'	
		-- and last_name = 'Murray'
			});
	$sth->execute ();
	while (my $contact_ref = $sth->fetchrow_hashref ()){
		m_strip_space ($contact_ref, $sth->{NAME});
		# print "$contact_ref->{id_num}\n";
		local $^W; # turn off strict flag
		if ($contact_ref->{oaa_sibling_gradyear_1} !~ /\D/ && $contact_ref->{oaa_sibling_gradyear_1} =~ /\d{4}/ && $contact_ref->{oaa_sibling_gradyear_1} > 2013 && $contact_ref->{oaa_sibling_gradyear_1} <= 2020){
			push @list, "$contact_ref->{id_num}\t";
			if ($contact_ref->{oaa_sibling_name_1} =~ /(.*?) (.*)/){
				push @list, "$1\t\t$2\t\t";
			} else {
				push @list, "$contact_ref->{oaa_sibling_name_1}\t\t$contact_ref->{last_name}\t\t";
			}
			push @list, "$contact_ref->{oaa_sibling_gradyear_1}\tFA\t";
			push @list, "$contact_ref->{addr_line_1}\t$contact_ref->{addr_line_2}\t$contact_ref->{city}\t$contact_ref->{state}\t$contact_ref->{zip}\t$contact_ref->{country}\t$contact_ref->{hs_ceeb}\t$contact_ref->{religion_code}\t$contact_ref->{church_ceeb}\n";
		}
		if ($contact_ref->{oaa_sibling_gradyear_2} !~ /\D/ && $contact_ref->{oaa_sibling_gradyear_2} =~ /\d{4}/ && $contact_ref->{oaa_sibling_gradyear_2} > 2013 && $contact_ref->{oaa_sibling_gradyear_2} <= 2020){
			push @list, "$contact_ref->{id_num}\t";
			if ($contact_ref->{oaa_sibling_name_2} =~ /(.*?) (.*)/){
				push @list, "$1\t\t$2\t\t";
			} else {
				push @list, "$contact_ref->{oaa_sibling_name_2}\t\t$contact_ref->{last_name}\t\t";
			}
			push @list, "$contact_ref->{oaa_sibling_gradyear_2}\tFA\t";
			push @list, "$contact_ref->{addr_line_1}\t$contact_ref->{addr_line_2}\t$contact_ref->{city}\t$contact_ref->{state}\t$contact_ref->{zip}\t$contact_ref->{country}\t$contact_ref->{hs_ceeb}\t$contact_ref->{religion_code}\t$contact_ref->{church_ceeb}\n";
		} 
		if ($contact_ref->{oaa_sibling_gradyear_3} !~ /\D/ && $contact_ref->{oaa_sibling_gradyear_3} =~ /\d{4}/ && $contact_ref->{oaa_sibling_gradyear_3} > 2013 && $contact_ref->{oaa_sibling_gradyear_3} <= 2020){
			push @list, "$contact_ref->{id_num}\t";
			if ($contact_ref->{oaa_sibling_name_3} =~ /(.*?) (.*)/){
				push @list, "$1\t\t$2\t\t";
			} else {
				push @list, "$contact_ref->{oaa_sibling_name_3}\t\t$contact_ref->{last_name}\t\t";
			}
			push @list, "$contact_ref->{oaa_sibling_gradyear_3}\tFA\t";
			push @list, "$contact_ref->{addr_line_1}\t$contact_ref->{addr_line_2}\t$contact_ref->{city}\t$contact_ref->{state}\t$contact_ref->{zip}\t$contact_ref->{country}\t$contact_ref->{hs_ceeb}\t$contact_ref->{religion_code}\t$contact_ref->{church_ceeb}\n";
		}
		if ($contact_ref->{oaa_sibling_gradyear_4} !~ /\D/ && $contact_ref->{oaa_sibling_gradyear_4} =~ /\d{4}/ && $contact_ref->{oaa_sibling_gradyear_4} > 2013 && $contact_ref->{oaa_sibling_gradyear_4} <= 2020){
			push @list, "$contact_ref->{id_num}\t";
			if ($contact_ref->{oaa_sibling_name_4} =~ /(.*?) (.*)/){
				push @list, "$1\t\t$2\t\t";
			} else {
				push @list, "$contact_ref->{oaa_sibling_name_4}\t\t$contact_ref->{last_name}\t\t";
			}
			push @list, "$contact_ref->{oaa_sibling_gradyear_4}\tFA\t";
			push @list, "$contact_ref->{addr_line_1}\t$contact_ref->{addr_line_2}\t$contact_ref->{city}\t$contact_ref->{state}\t$contact_ref->{zip}\t$contact_ref->{country}\t$contact_ref->{hs_ceeb}\t$contact_ref->{religion_code}\t$contact_ref->{church_ceeb}\n";
		}
		my $sth = $global{dbh_jenz}->prepare (qq{
			update candidate_udf set siblings_exported = 'yes'
			where
			id_num = ?
				});
		$sth->execute ($contact_ref->{id_num});
	}
	# open(OUT,">$global{g_path}reports/siblings/list.txt");
	open(OUT,">$global{g_path}import/siblings/list.txt");
	print OUT @list;
	close (OUT);

}

sub m_strip_space {
	my ($data_ref, $sth_names) = @_;
	foreach my $col_name (@{$sth_names}){
		$data_ref->{$col_name} =~ s/ *$// if defined $data_ref->{$col_name};
	}
}

sub action_list {
	if ($q->param('year')){
		$_[0]->weekly_report();
	} elsif ($q->param('gc_navigator')){
		$_[0]->gc_navigator();
	} elsif (ref($_[0]) =~ /::web$/){
		$_[0]->report_dashboard();
	} elsif ($q->param('rapid_insight_export')){
		$_[0]->rapid_insight_export();
	} elsif ($q->param('hs_certificates')){
		$_[0]->hs_certificates();
	} elsif ($q->param('pla_spreadsheet')){
		$_[0]->pla_spreadsheet();
	} elsif ($q->param('convention_list')){
		$_[0]->convention_list();
	} elsif ($q->param('run')){
		my $method = $q->param('run');	
		$_[0]->$method();
	} elsif ($q->param('hs_name_check')){
		$_[0]->hs_name_check();
	} else {
#		main::printer(ref($_[0]));
	}
#	$_[0]->make_file_duplicates();
#	$_[0]->layout();
#	main::j_job_end($_[0]->{_job_id}) if $global{page_ref}{lp_job_log} eq 'yes';
#	main::printer ('','output', @{$_[0]->{_error_log}}) if @{$_[0]->{_error_log}};
#	main::send_email ('', '', $global{page_ref}{lp_title}) if $global{g_localpath} eq '/insite/';
}

# local launch area
if ($global{object_marker} eq 'system::reports'){
	my $system_reports = system::reports->new ('call'=>'self_starter'); # initial initiation
	$system_reports->system::reports::action_list();
#	main::printer ('','output', @{$system_gm->{_error_log}}) if @{$system_gm->{_error_log}};
#	main::printer($system_gm->_get('test'));
}
1;
