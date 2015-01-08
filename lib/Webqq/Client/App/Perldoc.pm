package Webqq::Client::App::Perldoc;
use Exporter 'import';
use JSON;
use Webqq::Client::Util qw(console_stderr truncate);
@EXPORT = qw(Perldoc);
if($^O !~ /linux/){
    console_stderr "Webqq::Client::App::Perldoc只能运行在linux系统上\n";
    exit;
}
chomp(my $PERLDOC_COMMAND = `/bin/env which perldoc`);

my %last_module_time ;

sub Perldoc{
    my $msg = shift;
    return if time - $msg->{msg_time} > 10;
    my $client = shift; 
    my $perldoc_path = shift;
    $PERLDOC_COMMAND = $perldoc_path if defined $perldoc_path;
    if($msg->{content} =~/perldoc\s+-(v|f)\s+([^ ]+)/){
        my ($p,$v) = ($1,$2);
        $v=~s/"/\\"/;
        my $doc = '';
        open PERLDOC,qq{$PERLDOC_COMMAND -Tt -$p "$v" 2>&1|} or $doc = '@灰灰 run perldoc fail';
        while(<PERLDOC>){
            last if $.>10;
            $doc .= $_;
        }
        close PERLDOC;
        $doc=~s/\n*$/...\n/;
        if($p eq 'f'){
            if($doc=~/^No documentation for perl function/){
                $doc .= "http://perldoc.perl.org/index-functions.html";
            }
            else{
                $doc .= "See More: http://perldoc.perl.org/functions/$v.html";
            }
        }
        elsif($p eq 'v'){
            $doc .= "See More: http://perldoc.perl.org/perlvar.html";
        }

        $client->reply_message($msg,$doc) if $doc;
    }  

    elsif($msg->{content} =~ /perldoc\s+((\w+::)*\w+)/ or $msg->{content} =~ /((\w+::)+\w+)/){
        my $module = $1;
        my $is_perldoc = $msg->{content}=~/perldoc/;
        return if !$is_perldoc  and  time - $last_module_time{$msg->{type}}{$msg->{from_uin}}{$module} < 300;
        my $metacpan_api = 'http://api.metacpan.org/v0/module/';
        my $cache = $client->{cache_for_metacpan}->retrieve($module);                
        if(defined $cache){
            $client->reply_message($msg,$cache->{doc});
            $last_module_time{$msg->{type}}{$msg->{from_uin}}{$module} = time;
            return;
        }
        my @headers = ();
        $client->{asyn_ua}->get($metacpan_api . $module,@headers,sub{   
            my $response = shift;
            my $doc;
            my $json;
            my $code;
            if($client->{debug}){
                print "GET " . $metacpan_api . $module,"\n";
                #print $response->content;
            }
            eval{ $json = JSON->new->utf8->decode($response->content);};
            unless($@){ 
                if($json->{code} == 404){
                    $doc = 
                        "模块名称: $module ($json->{message})" ;
                    $code = 404;
                }
                else{
                    $code = 200;
                    my $author  =   $json->{author};
                    my $version =   $json->{version};
                    #my $date    =   $json->{date};
                    my $abstract=   $json->{abstract};
                    my $podlink     = 'https://metacpan.org/pod/' . $module;
                    $doc = 
                        "模块名称: $module\n" . 
                        "当前版本: $version\n" . 
                        "作者      : $author\n" . 
                        "简述      : $abstract\n" . 
                        "文档链接: $podlink\n"
                    ;
                }
                $client->{cache_for_metacpan}->store($module,{code=>$code,doc=>$doc},604800);
                $client->reply_message($msg,$doc) if $doc;
                $last_module_time{$msg->{type}}{$msg->{from_uin}}{$module} = time;
            }
        }); 
                
    }
}

1;
