class Icecream < Formula
  desc "Distributed compiler with a central scheduler to share build load"
  homepage ""
  url "https://github.com/icecc/icecream/releases/download/1.4/icecc-1.4.0.tar.gz"
  sha256 "884caebb93afa096e6d881677b9a432ae528bab297725f1d737a463ab45ba393"
  license "GPL-2.0"
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "docbook2x" => :build
  depends_on "libtool" => :build
  depends_on "libarchive"
  depends_on "lzo"
  depends_on "zstd"

  patch :p1, :DATA


  bottle do
    root_url "https://github.com/ppluciennik/brew/releases/download/icecream-1.4.0-p1"
    sha256 monterey:       "a8cef919b87d228ae17b8e3281d034bc553b9b0026b01a328fa5e6e71be1ab14"
    sha256 catalina:       "c073084eff5d8db890eb8c19878642ba34d7afdcf0762c784b97e1df66882021"
  end


  def install
    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --enable-clang-wrappers
    ]

    system "./configure", *args
    system "make", "install"

    # Manually install scheduler property list
    (prefix/"#{plist_name}-scheduler.plist").write scheduler_plist
  end

  def caveats
    <<~EOS
      To override the toolset with icecc, add to your path:
        #{opt_libexec}/icecc/bin
    EOS
  end

  service do
    run opt_sbin/"iceccd"
  end

  def scheduler_plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>Label</key>
          <string>#{plist_name}-scheduler</string>
          <key>ProgramArguments</key>
          <array>
          <string>#{sbin}/icecc-scheduler</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
      </dict>
      </plist>
    EOS
  end

  test do
    (testpath/"hello-c.c").write <<~EOS
      #include <stdio.h>
      int main()
      {
        puts("Hello, world!");
        return 0;
      }
    EOS
    system opt_libexec/"icecc/bin/gcc", "-o", "hello-c", "hello-c.c"
    assert_equal "Hello, world!\n", shell_output("./hello-c")

    (testpath/"hello-cc.cc").write <<~EOS
      #include <iostream>
      int main()
      {
        std::cout << "Hello, world!" << std::endl;
        return 0;
      }
    EOS
    system opt_libexec/"icecc/bin/g++", "-o", "hello-cc", "hello-cc.cc"
    assert_equal "Hello, world!\n", shell_output("./hello-cc")

    (testpath/"hello-clang.c").write <<~EOS
      #include <stdio.h>
      int main()
      {
        puts("Hello, world!");
        return 0;
      }
    EOS
    system opt_libexec/"icecc/bin/clang", "-o", "hello-clang", "hello-clang.c"
    assert_equal "Hello, world!\n", shell_output("./hello-clang")

    (testpath/"hello-cclang.cc").write <<~EOS
      #include <iostream>
      int main()
      {
        std::cout << "Hello, world!" << std::endl;
        return 0;
      }
    EOS
    system opt_libexec/"icecc/bin/clang++", "-o", "hello-cclang", "hello-cclang.cc"
    assert_equal "Hello, world!\n", shell_output("./hello-cclang")
  end
end

__END__
diff --git a/daemon/Makefile.am b/daemon/Makefile.am
index 4ce0d99..4ae696b 100644
--- a/daemon/Makefile.am
+++ b/daemon/Makefile.am
@@ -15,7 +15,8 @@ iceccd_LDADD = \
 	$(LIBARCHIVE_LIBS)

 AM_CPPFLAGS = \
-	-I$(top_srcdir)/services
+	-I$(top_srcdir)/services \
+	$(LIBARCHIVE_CFLAGS)

 AM_LIBTOOLFLAGS = --silent

