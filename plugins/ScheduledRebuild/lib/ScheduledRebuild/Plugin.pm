# $Id$

package ScheduledRebuild::Plugin;

use strict;
use warnings;
use YAML::Tiny;
use Data::Dumper;
use Data::Dump qw(dump);

sub plugin {
    return MT->component('ScheduledRebuild');
}

sub _log{
    my ($msg) = @_;
    return unless defined($msg);
    require MT;
    MT->log({message=>$msg});
    1;
}

sub get_config {
    my $plugin = plugin();
    my ($key, $blog_id) = @_;
    die "no blog id." unless $blog_id;
    my $scope = $blog_id ? 'blog:'.$blog_id : 'system';
    my %plugin_param;
    $plugin->load_config(\%plugin_param, $scope);
    my $value = $plugin_param{$key};
    $value;
}


sub do_rebuild {
    my ($blog_id, $yaml_string, $current_ts) = @_;
    my ($year, $month, $today, $hour, $min) = unpack ('A4A2A2A2A2', $current_ts);
    my $yaml_data = YAML::Tiny->read_string($yaml_string);
    my @list = @{$yaml_data->[0]};
    my $last_ts = get_config('scheduled_rebuild_last_time', $blog_id);
    foreach my $a (@list){
        my @time_table = ();
        my @hour = @{$a->{hour}};
        my @min  = @{$a->{min}};
        foreach my $h (@hour){
            my $h2 = sprintf("%02d", $h);
            foreach my $m (@min){
                my $m2 = sprintf("%02d", $m);
                my $target_ts = $year.$month.$today.$h2.$m2;
                push(@time_table,$target_ts);
            }

        }
        my $flag = 0;
        foreach my $target_ts (@time_table){
            $flag = 1 if (($target_ts > $last_ts) && ($target_ts <= $current_ts));
        }
        next unless ($flag);

        my @target_template_ids = @{$a->{id}};

        use MT::Template;
        use MT::FileInfo;
        use MT::WeblogPublisher;
        foreach my $id (@target_template_ids) {
            my $tmpl = MT::Template->load($id);
            next unless ($tmpl);
            my $tmpl_blog_id = $tmpl->blog_id;
            next if ($blog_id != $tmpl_blog_id);
            my @fileinfos = MT::FileInfo->load({template_id=>$id});
            next if (! @fileinfos);
            foreach my $fileinfo (@fileinfos) {
                my $file = $fileinfo->file_path;
                unlink($file);
                my $wp = MT::WeblogPublisher->new;
                $wp->rebuild_from_fileinfo($fileinfo);
            }
        }
    }

    1;
}

sub website_rebuild{
    my ($ts) = @_;
    require MT::Website;
    require MT::Util;
    my $plugin = plugin();
    my $websites = MT::Website->load_iter or die "no websites loading";
    CHECKBLOG: while (my $website = $websites->()) {
        my $id = $website->id;
        my $check_enable = get_config('scheduled_rebuild_enable', $id);
        next CHECKBLOG unless $check_enable;
        my $yaml = get_config('scheduled_rebuild_list', $id);
        next CHECKBLOG unless $yaml;
        my $epoch_ts = MT::Util::epoch2ts( $id, $ts );
        do_rebuild($id, $yaml, $epoch_ts);
        $plugin->set_config_value('scheduled_rebuild_last_time', $epoch_ts, 'blog:'.$id);
    }
    1;
}

sub blog_rebuild{
    my ($ts) = @_;
    require MT::Blog;
    require MT::Util;
    my $plugin = plugin();
    my $blogs = MT::Blog->load_iter or die "no websites loading";
    CHECKBLOG: while (my $blog = $blogs->()) {
        my $id = $blog->id;
        my $check_enable = get_config('scheduled_rebuild_enable', $id);
        next CHECKBLOG unless $check_enable;
        my $yaml = get_config('scheduled_rebuild_list', $id);
        next CHECKBLOG unless $yaml;
        my $epoch_ts = MT::Util::epoch2ts( $id, $ts );
        do_rebuild($id, $yaml, $epoch_ts);
        $plugin->set_config_value('scheduled_rebuild_last_time', $epoch_ts, 'blog:'.$id);
    }
    1;
}



#----- Task
sub do_scheduled_rebuild {
    my $ts =time();
    blog_rebuild($ts);
    website_rebuild($ts);
    1
}

1;
