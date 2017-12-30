class XcprojManager < Formula
  desc "Manager that creates xcode-projects supporting micro-features"
  homepage "https://github.com/anreitersimon/project-manager"
  url "https://github.com/anreitersimon/project-manager/archive/0.1.2.tar.gz"
  sha256 "0614ef4389b2df12ef24d9d9065bd7857899d18b9156216323094083caa4a842"
  head "https://github.com/anreitersimon/project-manager.git"

  depends_on :xcode

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end
end
