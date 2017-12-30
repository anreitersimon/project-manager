class XcprojManager < Formula
  desc "Manager that creates xcode-projects supporting micro-features"
  homepage "https://github.com/anreitersimon/project-manager"
  url "https://github.com/anreitersimon/project-manager/archive/0.1.1.tar.gz"
  sha256 "46e1acc18f208908f3abbfc0f6fcf9f500121d3194001f6dd7e20cd00bdd4c11"
  head "https://github.com/anreitersimon/project-manager.git"

  depends_on :xcode

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end
end
