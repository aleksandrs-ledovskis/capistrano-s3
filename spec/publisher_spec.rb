require 'spec_helper'

describe Capistrano::S3::Publisher do
  before do
    @root = File.expand_path('../', __FILE__)
    publish_file = Capistrano::S3::Publisher::LAST_PUBLISHED_FILE
    FileUtils.rm(publish_file) if File.exist?(publish_file)
  end

  describe "::files" do
    subject(:files) { described_class.files(deployment_path, exclusions) }

    let(:deployment_path) { "spec/sample-2" }
    let(:exclusions) { [] }

    it "includes dot-prefixed/hidden directories" do
      expect(files).to include("spec/sample-2/.well-known/test.txt")
    end

    it "includes dot-prefixed/hidden files" do
      expect(files).to include("spec/sample-2/public/.htaccess")
    end
  end

  context "on publish!" do
    it "publish all files" do
      Aws::S3::Client.any_instance.expects(:put_object).times(8)
      Capistrano::S3::Publisher.publish!('s3.amazonaws.com', 'abc', '123', 'mybucket.amazonaws.com', 'spec/sample', '', 'cf123', [], [], false, {}, 'staging')
    end

    it "publish only gzip files when option is enabled" do
      Aws::S3::Client.any_instance.expects(:put_object).times(4)
      Capistrano::S3::Publisher.publish!('s3.amazonaws.com', 'abc', '123', 'mybucket.amazonaws.com', 'spec/sample', '', 'cf123', [], [], true, {}, 'staging')
    end

    context "invalidations" do
      it "publish all files with invalidations" do
        Aws::S3::Client.any_instance.expects(:put_object).times(8)
        Aws::CloudFront::Client.any_instance.expects(:create_invalidation).once

        Capistrano::S3::Publisher.publish!('s3.amazonaws.com', 'abc', '123', 'mybucket.amazonaws.com', 'spec/sample', '', 'cf123', ['*'], [], false, {}, 'staging')
      end

      it "publish all files without invalidations" do
        Aws::S3::Client.any_instance.expects(:put_object).times(8)
        Aws::CloudFront::Client.any_instance.expects(:create_invalidation).never

        Capistrano::S3::Publisher.publish!('s3.amazonaws.com', 'abc', '123', 'mybucket.amazonaws.com', 'spec/sample', '', 'cf123', [], [], false, {}, 'staging')
      end
    end

    context "exclusions" do
      it "exclude one files" do
        Aws::S3::Client.any_instance.expects(:put_object).times(7)

        exclude_paths = ['fonts/cantarell-regular-webfont.svg']
        Capistrano::S3::Publisher.publish!('s3.amazonaws.com', 'abc', '123', 'mybucket.amazonaws.com', 'spec/sample', '', 'cf123', [], exclude_paths, false, {}, 'staging')
      end

      it "exclude multiple files" do
        Aws::S3::Client.any_instance.expects(:put_object).times(6)

        exclude_paths = ['fonts/cantarell-regular-webfont.svg', 'fonts/cantarell-regular-webfont.svg.gz']
        Capistrano::S3::Publisher.publish!('s3.amazonaws.com', 'abc', '123', 'mybucket.amazonaws.com', 'spec/sample', '', 'cf123', [], exclude_paths, false, {}, 'staging')
      end

      it "exclude directory" do
        Aws::S3::Client.any_instance.expects(:put_object).times(0)

        exclude_paths = ['fonts/**/*']
        Capistrano::S3::Publisher.publish!('s3.amazonaws.com', 'abc', '123', 'mybucket.amazonaws.com', 'spec/sample', '', 'cf123', [], exclude_paths, false, {}, 'staging')
      end
    end
  end
end
