module Runners

  def asciidoc_cmd(*args)
    options = { attrs: {} }.merge(args.extract_options!)
    cmd = ['asciidoc']
    options.delete(:attrs).each{|attr, val| cmd << '-a' << "#{attr}=#{val}" }
    cmd << "--out-file=#{options[:output_file]}" if options[:output_file]
    cmd += args
    cmd << book_file
    cmd
  end

  def a2x
    ["a2x", "--destination-dir=#{output_path}", "--keep-artifacts", "-f", product_type.to_s, "-d", "book", '--no-xmllint', ]
  end

  def a2x_wss
    a2x + ["--stylesheet=#{stylesheet_path('scribe.css')}"]
  end

  def xslt_cmd(jar_arguments, java_options)
    cmd = ['java']
    cmd << '-cp' << [asset_path('vendor', 'saxon.jar'), asset_path('vendor', 'xslthl-2.0.2.jar')].join(classpath_delimiter)
    cmd << "-Dxslthl.config=file://#{asset_path('docbook-xsl', 'highlighting', 'xslthl-config.xml')}"
    cmd += java_options.map{|attr,val| "-D#{attr}=#{val}" }
    cmd << 'com.icl.saxon.StyleSheet'
    cmd += Array(jar_arguments)
    cmd
  end
  def windows?() RbConfig::CONFIG['host_os'] =~ /mswin|windows|mingw|cygwin/i ; end
  def classpath_delimiter() windows? ? ';' : ':' ; end

end
