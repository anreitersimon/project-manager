class XcprojManager < Formula
  desc "Manager that creates xcode-projects supporting micro-features"
  homepage "https://github.com/anreitersimon/project-manager"
  url "https://github.com/anreitersimon/project-manager/archive/0.1.4.tar.gz"
  sha256 "9039a10461355675ba70174cd2cc89fb89913af1ff213bd41a9faa1d781be8ae"
  head "https://github.com/anreitersimon/project-manager.git"

  depends_on :xcode

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end
end
