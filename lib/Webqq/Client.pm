package Webqq::Client;
use Encode;
use LWP::Protocol::https;
use Storable qw(dclone);
use base qw(Webqq::Message Webqq::Client::Cron);
use Webqq::Client::Cache;
use Webqq::Message::Queue;

#定义模块的版本号
our $VERSION = "4.5";

use LWP::UserAgent;#同步HTTP请求客户端
use AnyEvent::UserAgent;#异步HTTP请求客户端

use Webqq::Client::Util qw(console);

#为避免在主文件中包含大量Method的代码，降低阅读性，故采用分文件加载的方式
#类似c语言中的.h文件和.c文件的关系
use Webqq::Client::Method::_prepare_for_login;
use Webqq::Client::Method::_check_verify_code;
use Webqq::Client::Method::_get_img_verify_code;
use Webqq::Client::Method::_login1;
use Webqq::Client::Method::_check_sig;
use Webqq::Client::Method::_login2;
use Webqq::Client::Method::_recv_message;
use Webqq::Client::Method::_get_group_info;
use Webqq::Client::Method::_get_group_sig;
use Webqq::Client::Method::_get_group_list_info;
use Webqq::Client::Method::_get_user_friends;
use Webqq::Client::Method::_get_user_info;
use Webqq::Client::Method::_get_friend_info;
use Webqq::Client::Method::_get_stranger_info;
use Webqq::Client::Method::_send_message;
use Webqq::Client::Method::_send_group_message;
use Webqq::Client::Method::_get_vfwebqq;
use Webqq::Client::Method::_send_sess_message;
use Webqq::Client::Method::logout;
use Webqq::Client::Method::get_qq_from_uin;
use Webqq::Client::Method::_get_msg_tip;


sub new {
    my $class = shift;
    my %p = @_;
    my $agent = 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062';
    my $self = {
        cookie_jar  => HTTP::Cookies->new(hide_cookie2=>1), 
        qq_param        =>  {
            qq                      =>  undef,
            pwd                     =>  undef,    
            is_need_img_verifycode  =>  0,
            img_verifycode_source  =>   'TTY',   #NONE|TTY|CALLBACK
            send_msg_id             =>  11111111+int(rand(99999999)),
            clientid                =>  11111111+int(rand(99999999)),
            psessionid              =>  'null',
            vfwebqq                 =>  undef,
            ptwebqq                 =>  undef,
            status                  =>  'online',
            passwd_sig              =>  '',
            verifycode              =>  undef,
            verifysession           =>  undef,
            md5_salt                =>  undef,
            cap_cd                  =>  undef,
            ptvfsession             =>  undef,
            api_check_sig           =>  undef,
            g_pt_version            =>  undef,
            g_login_sig             =>  undef,
            g_style                 =>  5,
            g_mibao_css             =>  'm_webqq',
            g_daid                  =>  164,
            g_appid                 =>  1003903,
            g_pt_version            =>  10092,
            rc                      =>  1,
        },
        qq_database     =>  {
            user        =>  {},
            friends     =>  [],
            group_list  =>  [],
            group       =>  [],
            discuss     =>  [],
        },
        cache_for_uin_to_qq     => Webqq::Client::Cache->new,
        cache_for_group_sig     => Webqq::Client::Cache->new,
        cache_for_stranger_info => Webqq::Client::Cache->new,
        cache_for_group         => Webqq::Client::Cache->new,
        cache_for_metacpan      => Webqq::Client::Cache->new,
        on_receive_message  =>  undef,
        on_send_message     =>  undef,
        on_login            =>  undef,
        on_new_friend       =>  undef,
        on_new_group        =>  undef,
        on_new_group_member =>  undef,
        on_input_img_verifycode => undef,
        receive_message_queue    =>  Webqq::Message::Queue->new,
        send_message_queue       =>  Webqq::Message::Queue->new,
        debug               => $p{debug}, 
        login_state         => "init",
        watchers            => {},
        type                => $p{type} || 'smartqq',#webqq or smartqq
        
    };
    $self->{ua} = LWP::UserAgent->new(
                cookie_jar  =>  $self->{cookie_jar},
                agent       =>  $agent,
                timeout     =>  300,
    );
    $self->{asyn_ua} = AnyEvent::UserAgent->new(
                cookie_jar  =>  $self->{cookie_jar},
                agent       =>  $agent,
                request_timeout =>  0,
                inactivity_timeout  =>  0,
    );
    $self->{qq_param}{from_uin}  =$self->{qq_param}{qq};
    if($self->{debug}){
        $self->{ua}->add_handler(request_send => sub {
            my($request, $ua, $h) = @_;
            print $request->as_string;
            return;
        });

        $self->{ua}->add_handler(
            response_header => sub { my($response, $ua, $h) = @_;
            print $response->as_string;
            return;
        });
    }
    $self->{default_qq_param} =  dclone($self->{qq_param});
    #全局变量，方便其他包引用$self
    $Webqq::Client::_CLIENT = $self;
    return bless $self;
}
sub on_send_message :lvalue {
    my $self = shift;
    $self->{on_send_message};
}

sub on_receive_message :lvalue{
    my $self = shift;
    $self->{on_receive_message};
}

sub on_login :lvalue {
    my $self = shift;
    $self->{on_login};
}

sub on_new_friend :lvalue {
    my $self = shift;
    $self->{on_new_friend};
}

sub on_new_group :lvalue {
    my $self = shift;
    $self->{on_new_group};
}

sub on_new_group_member :lvalue {
    my $self = shift;
    $self->{on_new_group_member};
}

sub on_input_img_verifycode :lvalue {
    my $self = shift;
    $self->{on_input_img_verifycode};
}

sub login{
    my $self = shift;
    my %p = @_;
    @{$self->{default_qq_param}}{qw(qq pwd)} = @p{qw(qq pwd)};
    @{$self->{qq_param}}{qw(qq pwd)} = @p{qw(qq pwd)};
    console "QQ账号: $self->{default_qq_param}{qq} 密码: $self->{default_qq_param}{pwd}\n";
    #my $is_big_endian = unpack( 'xc', pack( 's', 1 ) ); 
    $self->{qq_param}{qq} = $self->{default_qq_param}{qq};
    $self->{qq_param}{pwd} = pack "H*",lc $self->{default_qq_param}{pwd};

           $self->_prepare_for_login()    
        && $self->_check_verify_code()     
        && $self->_get_img_verify_code()   
        && $self->_login1()                
        && $self->_check_sig()             
        && $self->_get_vfwebqq()
        && $self->_login2();
    

    #登录不成功，客户端退出运行
    if($self->{login_state} ne 'success'){
        console "登录失败，客户端退出\n";
        exit;
    }
    else{
        console "登录成功\n";
    }
    #获取个人资料信息
    $self->update_user_info();  
    #显示欢迎信息
    $self->welcome();
    #更新好友信息
    $self->update_friends_info();
    #更新群信息
    $self->update_group_info();
    #执行on_login回调
    if(ref $self->{on_login} eq 'CODE'){
        $self->{on_login}->($self);
    }
    return 1;
}
sub relogin{
    my $self = shift;   
    console "正在重新登录...\n";
    $self->logout();
    $self->{login_state} = 'relogin';

    #清空cookie
    $self->{cookie_jar} = HTTP::Cookies->new(hide_cookie2=>1);
    $self->{ua}->cookie_jar($self->{cookie_jar});
    $self->{asyn_ua}->cookie_jar($self->{cookie_jar});
    #重新设置初始化参数
    $self->{qq_param} = dclone($self->{default_qq_param});
    #停止心跳请求
    undef $self->{timer_heartbeat};
    #重新设置一个心跳请求
    $self->{timer_heartbeat} = AE::timer 0 , 60 , sub{ $self->_get_msg_tip()};
    #$self->{cache_for_uin_to_qq} = Webqq::Client::Cache->new;
    #$self->{cache_for_group_sig} = Webqq::Client::Cache->new;
    $self->login(qq=>$self->{default_qq_param}{qq},pwd=>$self->{default_qq_param}{pwd});
}
sub _get_vfwebqq;
sub _prepare_for_login;
sub _check_verify_code;
sub _get_img_verify_code;
sub _check_sig;
sub _login1;
sub _login2;
sub _get_user_info;
sub _get_friend_info;
sub _get_group_info;
sub _get_group_list_info;
sub _get_user_friends;
sub _get_discuss_list_info;
sub _send_message;
sub _send_group_message;
sub _get_msg_tip;
sub change_status;
sub get_qq_from_uin;

#接受一个消息，将它放到发送消息队列中
sub send_message{
    my $self = shift;
    my $msg = shift;
    $self->{send_message_queue}->put($msg);
};
#接受一个群临时消息，将它放到发送消息队列中
sub send_sess_message{
    my $self = shift;
    my $msg = shift;
    $self->{send_message_queue}->put($msg);
}

#接受一个群消息，将它放到发送消息队列中
sub send_group_message{
    my $self = shift;
    my $msg = shift;
    $self->{send_message_queue}->put($msg);
};
sub welcome{
    my $self = shift;
    my $w = $self->{qq_database}{user};
    console "欢迎回来, $w->{nick}($w->{province})\n";
    console "个人说明: " . ($w->{personal}?$w->{personal}:"（无）") . "\n"
    #个人信息存储在$self->{qq_database}{user}中
    #    face
    #    birthday
    #    occupation
    #    phone
    #    allow
    #    college
    #    uin
    #    constel
    #    blood
    #    homepage
    #    stat
    #    vip_info
    #    country
    #    city
    #    personal
    #    nick
    #    shengxiao
    #    email
    #    client_type
    #    province
    #    gender
    #    mobile
 
};
sub logout;
sub run {
    my $self = shift;
    $self->_load_extra_accessor();
    #设置从接收消息队列中接收到消息后对应的处理函数
    $self->{receive_message_queue}->get(sub{
        my $msg = shift;
        #接收队列中接收到消息后，调用相关的消息处理回调，如果未设置回调，消息将丢弃
        if(ref $self->on_receive_message eq 'CODE'){
            $self->on_receive_message->($msg); 
        }
    });

    #设置从发送消息队列中提取到消息后对应的处理函数
    $self->{send_message_queue}->get(sub{
        my $msg = shift;
        my $rand_watcher_id = rand();
        #my $now = AE::now;
        #$self->{send_last_schedule_time} = $now  unless defined $self->{send_last_schedule_time};
        #$self->{send_last_schedule_time} += 1.5;
        #my $delay = $self->{last_send_schedule_time} - $now;
        $self->{watchers}{$rand_watcher_id} = AE::timer 1.5,0,sub{
            delete $self->{watchers}{$rand_watcher_id};
            $self->_send_message($msg)  if $msg->{type} eq 'message';
            $self->_send_group_message($msg)  if $msg->{type} eq 'group_message';
            $self->_send_sess_message($msg)  if $msg->{type} eq 'sess_message';
        };
    });


    console "开始接收消息\n";
    $self->_recv_message();
    console "客户端运行中...\n";
    #$self->{timer_heartbeat} = AE::timer 30 , 60 , sub{ $self->_get_msg_tip()};
    #$self->{timer_user_info} = AE::timer 30 , 60 , sub{ $self->update_user_info()};
    #$self->{timer_friends_info} = AE::timer 1800 , 1800 , sub{ $self->update_friends_info()};
    #$self->{timer_group_info} = AE::timer 1800 , 1800 , sub{
    #    $self->update_group_info();
    #};

    $self->{cv} = AE::cv;
    $self->{cv}->recv;
};
sub search_cookie{
    my($self,$cookie) = @_;
    my $result = undef;
    $self->{cookie_jar}->scan(sub{
        my($version,$key,$val,$path,$domain,$port,$path_spec,$secure,$expires,$discard,$rest) =@_;
        if($key eq $cookie){
            $result = $val ;
            return;
        }
    });
    return $result;
}

#根据uin进行查询，返回一个friend的hash引用
#这个hash引用的结构是：
#{
#    flag        #标志，作用未知
#    face        #表情
#    uin         #uin
#    categories  #所属分组
#    nick        #昵称
#    markname    #备注名称
#    is_vip      #是否是vip会员
#    vip_level   #vip等级
#}
sub search_friend {
    my ($self,$uin) = @_;
    for my $f( @{ $self->{qq_database}{friends} }){
        return dclone($f) if $f->{uin} eq $uin;
    } 
    #新增好友
    my $friend = $self->_get_friend_info($uin);
    if(defined $friend){
        push @{ $self->{qq_database}{friends} },$friend;
        if(ref $self->{on_new_friend} eq 'CODE'){
            $self->{on_new_friend}->($friend);
        }
        return $friend;
    }
    #新增陌生人(你是对方好友，但对方还不是你好友)
    else{
        my $tmp_friend = {
            uin =>  $uin,
            categories  => "陌生人",
            nick        => "昵称未知",
        };
        push @{ $self->{qq_database}{friends} },$tmp_friend;
        return $tmp_friend;
    }
}

#根据群的gcode和群成员的uin进行查询，返回群成员相关信息
#返回结果是一个群成员的hash引用
#{
#    nick        #昵称
#    province    #省份
#    gender      #性别
#    uin         #uin
#    country     #国家
#    city        #城市
#}
sub search_member_in_group{
    my ($self,$gcode,$member_uin) = @_;
    #在现有的群中查找
    for my $g (@{$self->{qq_database}{group}}){ 
        #如果群是存在的
        if($g->{ginfo}{code} eq $gcode){    
            #在群中查找指定的成员
            #如果群数据库中包含群成员数据
            if(exists $g->{minfo} and ref $g->{minfo} eq 'ARRAY'){
                for my $m(@{$g->{minfo} }){ 
                    #查到成员信息并返回
                    return dclone($m) if $m->{uin} eq $member_uin; 
                }
                #查不到成员信息，说明可能是新增的成员，重新更新一次群信息
                my $group_info = $self->_get_group_info($g->{ginfo}{code});
                #群成员信息更新成功
                if(defined $group_info and ref $group_info->{minfo} eq 'ARRAY'){
                    #再次查找新增的成员
                    for my $m (@{$group_info->{minfo}}){    
                        #找到新增的成员信息了
                        if($m->{uin} eq $member_uin){   
                            #更新到现有的群中并返回
                            push @{$g->{minfo} },$m;
                            if(ref $self->{on_new_group_member} eq 'CODE'){
                                $self->{on_new_group_member}->($g,$m);
                            }
                            return dclone($m);
                        }    
                    }
                    #仍然找不到信息，只好直接返回空了
                    return {};
                }
                #群成员信息更新失败
                else{
                    return {};
                }
            }
            #群数据中只有ginfo，没有minfo
            else{
                #尝试重新更新一下群信息，希望可以拿到minfo
                my $group_info = $self->_get_group_info($g->{ginfo}{code});         
                if(defined $group_info and ref $group_info->{minfo} eq 'ARRAY'){
                    #终于拿到minfo了 赶紧存起来 以备下次使用
                    $self->update_group_info($group_info);
                    #在minfo里找群成员
                    for my $m (@{$group_info->{minfo}}){
                        if($m->{uin} eq $member_uin){
                            #找到了赶紧返回
                            return dclone($m);
                        }
                    } 
                    #靠 还是没找到
                    return {};
                }
                #很可惜，还是拿不到minfo
                else{
                    return {};
                }
            }
        }
    }
    #遍历完整个群也没有匹配的群，说明群有新增了，需要更新群信息
    my $group_info = $self->_get_group_info($gcode);
    if(defined $group_info){
        #更新群列表信息
        #全局更新的话，担心webqq不支持（只允许启动的时候查询一次群列表）
        #$self->update_group_list_info();
        #更新群信息
        $self->update_group_info($group_info);
        $self->update_group_list_info({
            name    =>  $group_info->{ginfo}{name},
            gid     =>  $group_info->{ginfo}{gid},
            code    =>  $group_info->{ginfo}{code},
        });
        if(ref $group_info->{minfo} eq 'ARRAY'){
            for my $m (@{$group_info->{minfo}}){
                if($m->{uin} eq $member_uin){
                    return dclone($m);
                }
            }
        }
    }

    return {};
}

sub search_stranger{
    my($self,$tuin) = @_;
    for my $g ( @{$self->{qq_database}{group}} ){
        for my $m (@{ $g->{minfo}  }){
            if($m->{uin} eq $tuin){
                return dclone($m) ;
            }
        }
    } 
    $self->_get_stranger_info($tuin) || {};
}

#根据gcode查询对应的群信息,返回的是一个hash的引用
#{
#    face        #群头像
#    memo        #群描述
#    class       #群类型
#    fingermemo  #
#    code        #group_code
#    createtime  #创建时间
#    flag        #
#    level       #群等级
#    name        #群名称
#    gid         #gid
#    owner       #群拥有者
#}

sub search_group{
    my($self,$gcode) = @_;
    for(@{ $self->{qq_database}{group} }){
        return dclone($_->{ginfo}) if $_->{ginfo}{code} eq $gcode;
    }
    my $group_info = $self->_get_group_info($gcode);
    if(defined $group_info){
        $self->update_group_list_info({
            name    =>  $group_info->{ginfo}{name},
            gid     =>  $group_info->{ginfo}{gid},
            code    =>  $group_info->{ginfo}{code},
        });
        $self->update_group_info($group_info);
        if(ref $self->{on_new_group} eq 'CODE'){
            $self->{on_new_group}->($group_info);
        }
        return dclone($group_info->{ginfo});
    }
    else{ 
        return {};
    }
}
#sub search_group{
#    my($self,$gcode) = @_;
#    for(@{ $self->{qq_database}{group_list} }){
#        return dclone($_) if $_->{gcode} eq $gcode;
#    } 
#    return {};
#}

sub update_user_info{
    my $self = shift;   
    console "更新个人信息...\n";
    my $user_info = $self->_get_user_info();
    if(defined $user_info){
        for my $key (keys %{ $user_info }){
            if($key eq 'birthday'){
                $self->{qq_database}{user}{birthday} = 
                    encode("utf8", join("-",@{ $user_info->{birthday}}{qw(year month day)}  )  );
            }
            else{
                $self->{qq_database}{user}{$key} = encode("utf8",$user_info->{$key});
            }
        }
    }
    else{console "更新个人信息失败\n";}
}
sub update_friends_info{
    my $self=shift;
    my $friend = shift;
    if(defined $friend){
        for(@{ $self->{qq_database}{friends} }){
            if($_->{uin} eq $friend->{uin}){
                $_ = $friend;
                return;
            }
        }
        push @{ $self->{qq_database}{friends} },$friend;
        return;
    }
    console "更新好友信息...\n";
    my $friends_info = $self->_get_user_friends();
    if(defined $friends_info){
        my %categories ;
        my %info;
        my %marknames;
        my %vipinfo;
        for(@{ $friends_info->{categories}}){
            $categories{ $_->{'index'} } = {'sort'=>$_->{'sort'},name=>encode("utf8",$_->{name}) };
        }
        $categories{0} = {sort=>0,name=>'我的好友'};
        for(@{ $friends_info->{info}}){
            $info{$_->{uin}} = {face=>$_->{face},flag=>$_->{flag},nick=>encode("utf8",$_->{nick}),};
        }
        for(@{ $friends_info->{marknames} }){
            $marknames{$_->{uin}} = {markname=>encode("utf8",$_->{markname}),type=>$_->{type}};
        }
        for(@{ $friends_info->{vipinfo} }){
            $vipinfo{$_->{u}} = {vip_level=>$_->{vip_level},is_vip=>$_->{is_vip}};
        }

        $self->{qq_database}{friends} = $friends_info->{friends};
        for(@{ $self->{qq_database}{friends} }){
            my $uin = $_->{uin};
            $_->{categorie} = $categories{$_->{categories}}{name};
            $_->{nick}  = $info{$uin}{nick};
            $_->{face} = $info{$uin}{face};
            $_->{markname} = $marknames{$uin}{markname};
            $_->{is_vip} = $vipinfo{$uin}{is_vip};
            $_->{vip_level} = $vipinfo{$uin}{vip_level};
        }
    }
    else{console "更新好友信息失败\n";}
    
}
sub update_group_info{
    my $self = shift;
    my $group = shift;
    if(defined $group){
        for( @{$self->{qq_database}{group}} ){
            if($_->{ginfo}{code} eq $group->{ginfo}{code} ){
                $_ = $group;
                return;
            }
        } 
        push @{$self->{qq_database}{group}},$group;
        return;
    }
    $self->update_group_list_info();
    for my $gl (@{ $self->{qq_database}{group_list} }){
        console "更新[ $gl->{name} ]群信息...\n";
        my $group_info = $self->_get_group_info($gl->{code});
        if(defined $group_info){
            if(ref $group_info->{minfo} ne 'ARRAY'){
                console "更新[ $gl->{name} ]成功，但暂时没有获取到群成员信息...\n";
            }
            if( @{$self->{qq_database}{group}} > 0 ){
                for( @{$self->{qq_database}{group}} ){
                    if($_->{ginfo}{code} eq $group_info->{ginfo}{code} ){
                        $_ = $group_info;
                        last;
                    }
                }
                push @{ $self->{qq_database}{group} }, $group_info;
            }
            else{
                push @{ $self->{qq_database}{group} }, $group_info;
            }
        }
        else{console "更新[ $gl->{name} ]群信息失败\n";}
            
    }
}
sub update_group_list_info{
    my $self = shift;
    my $group = shift;
    if(defined $group ){
        for(@{ $self->{qq_database}{group_list} }){
            if($_->{code} eq $group->{code}){
                $_ = $group;
                return;        
            }
        }
        push @{ $self->{qq_database}{group_list} }, $group;
        return;
    }
    console "更新群列表信息...\n";
    my $group_list_info = $self->_get_group_list_info();
    if(defined $group_list_info){
        $self->{qq_database}{group_list} =  $group_list_info->{gnamelist}; 
        my %gmarklist;
        for(@{ $group_list_info->{gmarklist} }){
            $gmarklist{$_->{uin}} = $_->{markname};
        }
        for(@{ $self->{qq_database}{group_list} }){
            $_->{markname} = $gmarklist{$_->{gid}};
            $_->{name} = encode("utf8",$_->{name});
        }
    }
    else{console "更新群列表信息失败\n";}    
}

sub get_group_code_from_gid {
    my $self = shift;
    my $gid = shift;
    my $group_code = undef;
    for my $g (@{ $self->{qq_database}{group_list} }){
        if($g->{gid} eq $gid){
            $group_code = $g->{code};
            last;
        }
    }
    return $group_code;
}

1;
__END__

