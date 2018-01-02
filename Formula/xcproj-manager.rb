class XcprojManager < Formula
  desc "Manager that creates xcode-projects supporting micro-features"
  homepage "https://github.com/anreitersimon/project-manager"
  url "https://github.com/anreitersimon/project-manager/archive/0.1.3.tar.gz"
  sha256 "ddb0ee636b8368453b20d115978e0d2ef395d36bf69a905a1b3133cfd1560e51"
  head "https://github.com/anreitersimon/project-manager.git"

  depends_on :xcode

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end
end
