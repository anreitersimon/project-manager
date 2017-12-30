class XCProjManager < Formula
  desc "Manager that creates xcode-projects supporting micro-features"
  homepage "https://github.com/anreitersimon/project-manager"
  url "https://github.com/anreitersimon/project-manager/archive/0.0.1.tar.gz"
  sha256 "037a6580a5e7cc0996d6d363ae1c96f063913490e57157b5d5ca5b49bbf86e74"
  head "https://github.com/anreitersimon/project-manager.git"

  depends_on :xcode

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end
end
