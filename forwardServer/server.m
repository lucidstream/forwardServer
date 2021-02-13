//
//  server.m
//  forward.server
//
//  Created by lucid on 2021/1/9.
//

#import "server.h"
#import "libForwardServer.h"

#define SPRINGBOARD_PREFERENCE @"/private/var/mobile/Library/Preferences/springboard.forwardServer.settings.plist"
#define SSHTUNNEL_PREFERENCE @"/private/var/mobile/Library/Preferences/sshtunnel.forwardServer.settings.plist"



__attribute__((constructor)) static void entry() {
    NSThread* springBoardThread = [[NSThread alloc] initWithBlock:^{
        NSMutableDictionary* plist = [[NSMutableDictionary alloc] initWithContentsOfFile:SPRINGBOARD_PREFERENCE];
        BOOL isEnableForward = [[plist objectForKey:@"IsEnableForward"] boolValue];
        NSString* springBoardListenAddr = [plist objectForKey:@"SpringBoardListenAddr"];
        signed long sbsMaxClientConn = [[plist objectForKey:@"SbsMaxClientConn"] intValue];
        NSString* sbsClientConnKeepAlive = [plist objectForKey:@"SbsClientConnKeepAlive"];
        if ( sbsClientConnKeepAlive != nil && ![sbsClientConnKeepAlive isEqualToString:@""] ) {
            sbsClientConnKeepAlive = [sbsClientConnKeepAlive stringByAppendingString:@"s"];
        }
        NSString* localTargetAddr = [plist objectForKey:@"SbsLocalTargetAddr"];
        
        //设置springboard监听地址
        GoString _springboardListenAddr;
        _springboardListenAddr.p = [springBoardListenAddr UTF8String];
        _springboardListenAddr.n = [springBoardListenAddr length];
        SetSpringBoardListenAddr(_springboardListenAddr);
        
        //设置最大客户连接数
        SetSbsMaxClientConn((GoInt64)sbsMaxClientConn);
        
        //设置客户机连接keepAlive
        const char* error = NULL;
        GoString _sbsclientConnKeepAlive;
        _sbsclientConnKeepAlive.p = [sbsClientConnKeepAlive UTF8String];
        _sbsclientConnKeepAlive.n = [sbsClientConnKeepAlive length];
        SetSbsClientConnKeepAlive(_sbsclientConnKeepAlive,(GoUintptr)&error);
        if ( NULL != error ) {
            return;
        }
        
        //设置转发目标地址
        GoString _localTargetAddr;
        _localTargetAddr.p = [localTargetAddr UTF8String];
        _localTargetAddr.n = [localTargetAddr length];
        SetSBSLocalTargetAddr(_localTargetAddr);
        
        if ( isEnableForward ) {
            SpringBoardForwardListen();
        }
    }];
    springBoardThread.name=@"springboard_forward_server";
    
    
    
    NSThread* sshTunnelThread = [[NSThread alloc] initWithBlock:^{
        NSMutableDictionary* plist = [[NSMutableDictionary alloc] initWithContentsOfFile:SSHTUNNEL_PREFERENCE];
        BOOL isEnableForward = [[plist objectForKey:@"IsEnableForward"] boolValue];
        NSString* sshServerAddr = [plist objectForKey:@"SSHServerAddr"];
        NSString* sshServerListenAddr = [plist objectForKey:@"SSHServerListenAddr"];
        signed long sshMaxClientConn = [[plist objectForKey:@"SSHMaxClientConn"] intValue];
        NSString* sshClientConnKeepAlive = [plist objectForKey:@"SSHClientConnKeepAlive"];
        if ( sshClientConnKeepAlive != nil && ![sshClientConnKeepAlive isEqualToString:@""] ) {
            sshClientConnKeepAlive = [sshClientConnKeepAlive stringByAppendingString:@"s"];
        }
        NSString* sshLocalTargetAddr = [plist objectForKey:@"SSHLocalTargetAddr"];
        
        //SSH服务连接地址
        GoString _sshServerAddr;
        _sshServerAddr.p = [sshServerAddr UTF8String];
        _sshServerAddr.n = [sshServerAddr length];
        SetSSHServerAddr(_sshServerAddr);

        //SSH服务端监听端口
        GoString _sshServerListenAddr;
        _sshServerListenAddr.p = [sshServerListenAddr UTF8String];
        _sshServerListenAddr.n = [sshServerListenAddr length];
        SetSSHServerListenAddr(_sshServerListenAddr);

        //SSH服务端客户机最大连接数
        SetSSHMaxClientConn((GoInt64)sshMaxClientConn);

        //SSH服务端客户端持久连接间隔
        const char* error = NULL;
        GoString _keepAliveDur;
        _keepAliveDur.p = [sshClientConnKeepAlive UTF8String];
        _keepAliveDur.n = [sshClientConnKeepAlive length];
        SetSSHClientConnKeepAlive(_keepAliveDur, (GoUintptr)&error);

        //ssh转发目标地址
        GoString _localTargetAddr;
        _localTargetAddr.p = [sshLocalTargetAddr UTF8String];
        _localTargetAddr.n = [sshLocalTargetAddr length];
        SetSSHLocalTargetAddr(_localTargetAddr);
        
        if ( isEnableForward ) {
            SSHTunnelForwardListen();
        }
    }];
    sshTunnelThread.name=@"sshtunnel_forward_server";
    
    NSThread* initThread = [[NSThread alloc] initWithBlock:^{
        const char* error = NULL;
       //初始化日志
       InitialLogSetting(0,(GoUintptr)&error);
       if ( NULL != error ) {
           return;
       }
       [springBoardThread start];
       [sshTunnelThread start];
    }];
    [initThread start];
}
