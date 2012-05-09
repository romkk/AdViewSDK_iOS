#!/usr/bin/env python
#-*- coding: utf-8 -*-
import os, sys
import shutil
import subprocess

program_path= os.path.realpath(sys.argv[0])

sdk_srcroot_dir = os.path.dirname (program_path)

sdk_dist_dir = os.path.join(sdk_srcroot_dir, 'dist')
sdk_xcode_build_dir = os.path.join (sdk_srcroot_dir, 'build')

sdk_dist_package_path= os.path.join(sdk_dist_dir, 'AdViewSDK')

sdk_dist_deploy_framework_name = 'AdView'
sdk_dist_universal_arch = ['armv6', 'armv7', 'i386']

sdk_version_file = os.path.join (sdk_srcroot_dir, 'VERSIONS')
sdk_readme_file = os.path.join (sdk_srcroot_dir, 'README.txt')
sdk_changelog_file = os.path.join (sdk_srcroot_dir, 'ChangeLog.txt')
sdk_manual_file = os.path.join (sdk_srcroot_dir, 'UserManual.pdf')

sdk_src_dirname = 'AdViewSDK'

sdk_src_public_headers = map (lambda (x): os.path.join (sdk_srcroot_dir, sdk_src_dirname, x), ['AdViewView.h', 'AdViewDelegateProtocol.h'])

extra_opensource_projects = map (lambda (x): os.path.join (sdk_srcroot_dir, x), ['TouchJSON', 'SBJson', 'JSONKit', 'ASIHTTPRequest', 'LBSSDK.framework'])
extra_opensource_ditto_filter = ['', '.h', '.m', '.mm', '.c', '.cpp', '.hpp', '.cc', '.cxx', '.hh']
extra_3rd_libraries = map (lambda (x): os.path.join (sdk_srcroot_dir, x), ['AdNetworks'])
extra_3rd_ditto_filter = ['.a', '.xib', '.nib', '.png', '.plist']

sdk_build_xcode_max_version = '4.2'
sdk_build_test_macros = ['USER_TEST_SERVER', 'DEBUG_INFO']
sdk_build_check_debug_file = os.path.join (sdk_srcroot_dir, sdk_src_dirname, 'internal/AdViewViewImpl.h')
sdk_build_get_version = ''

sdk_build_target_name = 'libAdViewSDK.a'
sdk_build_target_product = 'libAdViewSDK.a'

def ditto_filter (dst_dir, src_dir, filter):
    for root, dirs, files in os.walk (os.path.realpath (src_dir)):
        for x in files:
            p = os.path.splitext (x)
            if p[1].lower () in filter:
                relative_dir = os.path.relpath (root, start = os.path.realpath (src_dir))
                cp_dst_dir = os.path.join (os.path.realpath (dst_dir), relative_dir)
                if not os.path.exists (cp_dst_dir):
                    os.makedirs (cp_dst_dir, mode = 0766)
                shutil.copy (os.path.join (root, x), cp_dst_dir)

def check_toolchain ():
    import re
    p = subprocess.Popen ('xcodebuild -version', stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
    out = p.stdout.readlines ()
    pattern = re.compile (r'Xcode\s*([\d\.]+)')
    m = pattern.match (out[0])
    if m is not None:
        return m.group (1) < sdk_build_xcode_max_version
    else:
        return False

def sdk_version ():
    with open (sdk_version_file, 'r') as f:
        version = f.read ().strip ()

    if not version:
        return 'unknown'
    else:
        return version

def check_release_one (test_macro):
    import re
    pattern = re.compile (r'^\s*#define\s+%s\s+(\d+)?\s*$' % test_macro)
    with open (sdk_build_check_debug_file, 'r') as f:
        linenum = 0
        for line in f.readlines ():
            linenum += 1
            m = pattern.match (line)
            if m is not None:
                macro_value = int (m.group(1))
                if macro_value:
                    print '! You must modify the macro: "%s" in file: %s line: %d' % (test_macro, sdk_build_check_debug_file, linenum)
                    return False
                else:
                    return True

def check_release ():
    for x in sdk_build_test_macros:
        if not check_release_one (x):
            return False;
    return True

def build_universal ():
    config = 'Release'
    current_dirname = os.getcwd ()
    os.chdir (sdk_srcroot_dir)
    tasks = [
            {'target' : 'AdViewSDK', 'config' : config, 'sdk' : 'iphoneos'},
            {'target' : 'AdViewSDK', 'config' : config, 'sdk' : 'iphonesimulator'},
            ]
    for t in tasks:
        retval = subprocess.call (['xcodebuild', '-target', t['target'], '-configuration', t['config'], '-sdk', t['sdk']])
        if retval != 0:
            print >> sys.stderr, '=' * 30
            print >> sys.stderr, 'Build!!!!!!'
            print >> sys.stderr, '=' * 30
            sys.exit (1)
    adview_libraries = map (lambda (x): os.path.join (sdk_xcode_build_dir, x, sdk_build_target_name),
            ['%s-iphoneos' % config, '%s-iphonesimulator' % config])
    framework_dir = os.path.join ( '%s-%s' % (sdk_dist_package_path,  sdk_version()), sdk_dist_deploy_framework_name)
    universal_target = os.path.join (framework_dir, sdk_build_target_product)
    if not os.path.exists (framework_dir):
        os.makedirs (framework_dir, 0766)
    cmd_list = ['lipo', '-output', universal_target, '-create']
    cmd_list.extend (adview_libraries)
    retval = subprocess.call (cmd_list)

    if retval != 0:
        print >> sys.stderr, '=' * 30
        print >> sys.stderr, 'Build!!!!!!'
        print >> sys.stderr, '=' * 30
        sys.exit (1)
    os.chdir (current_dirname)

    cmd_list = ['lipo', '-info', universal_target]

    p = subprocess.Popen ('lipo -info %s' % universal_target, stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
    out = p.stdout.readlines ()
    output_infomation = out[0]
    for x in sdk_dist_universal_arch:
        if x not in output_infomation:
            print >> sys.stderr, '%s is not containts %s code!!!!' % (universal_target, x)
            sys.exit (1)

def build_dist ():
    package_dir = '%s-%s' % (sdk_dist_package_path, sdk_version())
    framework_dir = os.path.join ( '%s-%s' % (sdk_dist_package_path,  sdk_version()), sdk_dist_deploy_framework_name)
    if not os.path.exists (framework_dir):
        os.makedirs (framework_dir, 0766)

    for x in sdk_src_public_headers:
        shutil.copy (x, framework_dir)

    for x in extra_opensource_projects:
        basename = os.path.basename (x)
        ditto_filter (os.path.join (package_dir, basename), x, extra_opensource_ditto_filter)

    for x in extra_3rd_libraries:
        basename = os.path.basename (x)
        ditto_filter (os.path.join (package_dir, basename), x, extra_3rd_ditto_filter)

    for x in [sdk_version_file, sdk_readme_file, sdk_changelog_file, sdk_manual_file]:
        shutil.copy (x, package_dir)

def build_ziparchive ():
    pass

if __name__ == '__main__':
    if not check_toolchain ():
        print >> sys.stderr, 'Xcode version error'
        sys.exit (1)

    for x in [sdk_dist_dir, sdk_xcode_build_dir]:
        if os.path.exists (x):
            shutil.rmtree (x)

    if not check_release ():
        print >> sys.stderr, 'Xcode version error'
        sys.exit (1)
    build_dist ()
    build_universal ()
    build_ziparchive ()
