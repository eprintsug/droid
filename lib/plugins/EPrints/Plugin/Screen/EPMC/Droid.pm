#####################################################################
#
# EPrints::Plugin::Screen::EPMC::Droid
#
######################################################################
#
#  __COPYRIGHT__
#
# Copyright 2000-2011 University of Southampton. All Rights Reserved.
# 
#  __LICENSE__
#
######################################################################
package EPrints::Plugin::Screen::EPMC::Droid;

@ISA = ( 'EPrints::Plugin::Screen::EPMC' );

use strict;
# Make the plug-in
sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{actions} = [qw( enable disable configure update )];
	$self->{disable} = 0; # always enabled, even in lib/plugins
	
	$self->{package_name} = "droid";

	return $self;
}

=item $screen->action_enable( [ SKIP_RELOAD ] )

Enable the L<EPrints::DataObj::EPM> for the current repository.

If SKIP_RELOAD is true will not reload the repository configuration.

=cut

sub action_enable
{
	my( $self, $skip_reload ) = @_;
	
	my $repository = $self->{repository};

	$self->SUPER::action_enable( $skip_reload );

	my $url = 'http://freefr.dl.sourceforge.net/project/droid/droid/4.0.0/droid-4.0.0-linux.tar.gz';
	my $file = File::Temp->new( SUFFIX => ".tgz");
	my $dir = File::Temp->newdir( CLEANUP => 0 );

	my $ua = LWP::UserAgent->new;

	my $response = $ua->get($url, ':content_file' => "$file");
	
	if (!($response->is_success)) {
		$self->{processor}->add_message( "warning", $repository->xml->create_text_node("Failed to download DROID, please try and install this package again"));
	}

	my $archive_format = "targz";

	my $rc = $repository->exec(
		$archive_format,
		DIR => $dir,
		ARC => $file );

	my $needed_dir = $repository->config("lib_path") . "/bin";

	use File::Path;
	use File::Copy;
	mkpath($needed_dir);
	move($dir . "/droid-4.0.0-linux/DROID/",$needed_dir . "/DROID/"); 

	if ($self->java_check()) 
	{
		$self->action_update();
	}

	EPrints::DataObj::EventQueue->create_unique( $repository, {
		pluginid => "Event",
		action => "cron",
		params => ["0 2 * * *",
			"Screen::EPMC::Droid",
			"action_update",
		],
	});

}

sub action_disable
{
	my( $self, $skip_reload ) = @_;
        
	my $repository = $self->{repository};

	my $epm = $self->{processor}->{dataobj};
	my @repos = $epm->repositories();
	if (scalar(@repos) < 2) {
		use File::Path;
		rmtree( $repository->config("lib_path") . "/bin/DROID/" );
	}

	my $event = EPrints::DataObj::EventQueue->new_from_hash( $repository, {
		pluginid => "Event",
		action => "cron",
		params => ["0 2 * * *",
			"Screen::EPMC::Droid",
			"action_update",
		],
	});
	$event->delete if (defined $event);

	$self->SUPER::action_disable( $skip_reload );
}

sub action_update
{
	my ( $self ) = @_;

	my $repository = $self->{repository};

	my $sig = $repository->get_conf( "droid_sig_file" );

	$repository->exec( "droid_update",
			SIGFILE => "$sig",
			);
	$repository->exec( "droid_rehash",
			SIGFILE => "$sig",
			);
}

sub java_check 
{
	
	my ( $self ) = @_;

	my $repository = $self->{repository};

	my $java = $repository->get_conf( 'executables', 'java' );
	
	if (!defined $java) {
		$java = 'java';
	}
	
	my $ret = `$java -version 2>&1`;

	my $index = index $ret,"gij";
	
	if ($index > 0) {
		$self->{processor}->add_message( "warning", $repository->xml->create_text_node("Sun/Oracle Java is not installed/configured"));
		return undef;
	} else {
		$index = 0;
		$index = index $ret,"Environment";
		if ($index > 0) {
		} else {
			return undef;
			$self->{processor}->add_message( "warning",$repository->xml->create_text_node("Sun/Oracle Java is not installed/configured"));
		}
	}

	return 1;
}

sub allow_configure { shift->can_be_viewed( @_ ) }

sub action_configure
{
	my( $self ) = @_;

	my $epm = $self->{processor}->{dataobj};
	my $epmid = $epm->id;

	foreach my $file ($epm->installed_files)
	{
		my $filename = $file->value( "filename" );
		next if $filename !~ m#^epm/$epmid/cfg/cfg\.d/(.*)#;
		my $url = $self->{repository}->current_url( host => 1 );
		$url->query_form(
			screen => "Admin::Config::View::Perl",
			configfile => "cfg.d/droid.pl",
		);
		$self->{repository}->redirect( $url );
		exit( 0 );
	}

	$self->{processor}->{screenid} = "Admin::EPM";

	$self->{processor}->add_message( "error", $self->html_phrase( "missing" ) );
}

1;
