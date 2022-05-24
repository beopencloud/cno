# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Cnoctl < Formula
  version "1.0.0"
  desc "An open source platform to onboard easily and securely organizational teams on multi-cloud Kubernetes clusters from a single console."
  homepage "https://www.beopenit.com/"
  url "https://github.com/beopencloud/cno/releases/download/v#{version}/cnoctl_v#{version}_Darwin_x86_64.tar.gz"
  sha256 "5e3ec2be3ea9c38d6a6eeea043728cc9bd0585ba473e9cbc60b3a1b6b781c8a7"
  license ""

  # depends_on "cmake" => :build

  def install
    bin.install "cnoctl"
    # ENV.deparallelize  # if your formula fails when building in parallel
    # Remove unrecognized options if warned by configure
    # https://rubydoc.brew.sh/Formula.html#std_configure_args-instance_method
    # system "./configure", *std_configure_args, "--disable-silent-rules"
    # system "cmake", "-S", ".", "-B", "build", *std_cmake_args
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test cno`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "#{bin}/cnoctl", "--help"
  end
end
