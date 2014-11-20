import optparse
import os
import glob
import sys

from s3_parallel_put import main as parallel_upload


def upload_build(project_name, num_processes=None, s3_access_key_id=None, s3_secret_access_key=None):
    if s3_secret_access_key is None or s3_secret_access_key is None:
        sys.exit('Cannot upload %s. The s3 access key and secret are not available. They must be passed via environment variables or the command line options.' % project_name)

    if num_processes is None or num_processes == 0:
        num_processes = 2

    os.environ['AWS_ACCESS_KEY_ID'] = s3_access_key_id
    os.environ['AWS_SECRET_ACCESS_KEY'] = s3_secret_access_key

    parallel_upload_command = ['s3-parallel-put.py', '--insecure', '--bucket=hubspot-static2cdn', '--put=stupid', '--grant=public-read', '--quiet', '--content-type=guess']
    parallel_upload_pointers_command = ['s3-parallel-put.py', '--insecure', '--bucket=hubspot-static2cdn', '--put=stupid', '--grant=public-read', '--quiet', '--content-type=text/plain']

    # Upload the archives first to ensure they are fully uploaded
    # before the "pointer" files are changed (to prevent update-deps
    # from trying to download non-fully baked static archives)
    archive_files = glob.glob("%(project_name)s*.tar.gz" % locals())

    cmd = parallel_upload_command + ['--processes=%s' % num_processes] + archive_files
    print "\nUploading archive files: %s ..." % ', '.join(archive_files)
    parallel_upload(cmd)


    # Next upload all the static assets (both debug and compressed folders)
    static_build_folders = glob.glob('%(project_name)s/static-*' % locals())

    cmd = parallel_upload_command + ['--processes=%s' % num_processes] + static_build_folders
    print "\nUploading all static files ..."
    parallel_upload(cmd)


    # Upload all of the "exported" non-versioned assets
    assets_to_export = glob.glob('%(project_name)s/ex/*' % locals())

    if len(assets_to_export) > 0:
        cmd = parallel_upload_command + ['--processes=%s' % num_processes] + assets_to_export
        print "\nUploading exported assets to non-versioned URL: ...\n\t%s\n\n" % "\n\t ".join(assets_to_export)
        parallel_upload(cmd)


    # Lastly upload all of the "pointer" files (so that everything is in
    # place before the pointers are changed)
    pointer_files = glob.glob("%(project_name)s/current*" % locals()) + \
                    glob.glob("%(project_name)s/edge*" % locals()) + \
                    glob.glob("%(project_name)s/latest*" % locals())

    cmd = parallel_upload_pointers_command + ['--processes=%s' % num_processes] + pointer_files
    print "\nUploading all pointers: %s ..." % ', '.join(pointer_files)
    parallel_upload(cmd)



# Note, this is expected to be run in the current directory of the compiled output
def main():
    parser = optparse.OptionParser()

    parser.add_option('-p', '--project-name', dest='project_name')
    parser.add_option('-P', '--processes', dest='num_processes')
    parser.add_option('--s3_access_key_id', dest='s3_access_key_id')
    parser.add_option('--s3_secret_access_key', dest='s3_secret_access_key')

    options, args = parser.parse_args()

    upload_build(
        options.project_name,
        num_processes = None if options.num_processes is None else int(options.num_processes),
        s3_access_key_id = options.s3_access_key_id or os.environ.get('BENDER_S3_ACCESS_KEY_ID'),
        s3_secret_access_key = options.s3_secret_access_key or os.environ.get('BENDER_S3_SECRET_ACCESS_KEY')
    )

if __name__ == "__main__":
    main()

