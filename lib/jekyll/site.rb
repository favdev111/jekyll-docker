module Jekyll
  
  class Site
    attr_accessor :source, :dest
    attr_accessor :layouts, :posts
    
    # Initialize the site
    #   +source+ is String path to the source directory containing
    #            the proto-site
    #   +dest+ is the String path to the directory where the generated
    #          site should be written
    #
    # Returns <Site>
    def initialize(source, dest)
      self.source = source
      self.dest = dest
      self.layouts = {}
      self.posts = []
    end
    
    # Do the actual work of processing the site and generating the
    # real deal.
    #
    # Returns nothing
    def process
      self.read_layouts
      self.transform_pages
      self.write_posts
    end
    
    # Read all the files in <source>/_layouts into memory for
    # later use.
    #
    # Returns nothing
    def read_layouts
      base = File.join(self.source, "_layouts")
      entries = Dir.entries(base)
      entries = entries.reject { |e| File.directory?(File.join(base, e)) }
      
      entries.each do |f|
        name = f.split(".")[0..-2].join(".")
        self.layouts[name] = Layout.new(base, f)
      end
    rescue Errno::ENOENT => e
      # ignore missing layout dir
    end
    
    # Read all the files in <base>/_posts and create a new Post
    # object with each one.
    #
    # Returns nothing
    def read_posts(base)
      entries = Dir.entries(base)
      entries = entries.reject { |e| File.directory?(File.join(base, e)) }

      # first pass processes, but does not yet render post content
      entries.each do |f|
        if Post.valid?(f)
          post = Post.new(base, f)
          self.posts << post
        end
      end
      
      # second pass renders each post now that full site payload is available
      self.posts.each do |post|
        post.render(self.layouts, site_payload)
      end
      
      self.posts.sort!
    rescue Errno::ENOENT => e
      # ignore missing layout dir
    end
    
    # Write each post to <dest>/<year>/<month>/<day>/<slug>
    #
    # Returns nothing
    def write_posts
      self.posts.each do |post|
        post.write(self.dest)
      end
    end
    
    # Copy all regular files from <source> to <dest>/ ignoring
    # any files/directories that are hidden (start with ".") or contain
    # site content (start with "_") unless they are "_posts" directories
    #   The +dir+ String is a relative path used to call this method
    #            recursively as it descends through directories
    #
    # Returns nothing
    def transform_pages(dir = '')
      base = File.join(self.source, dir)
      entries = Dir.entries(base)
      entries = entries.reject do |e|
        (e != '_posts') and ['.', '_'].include?(e[0..0])
      end

      # we need to make sure to process _posts *first* otherwise they 
      # might not be available yet to other templates as {{ site.posts }}
      if entries.include?('_posts')
        entries.delete('_posts')
        read_posts(File.join(base, '_posts'))
      end

      entries.each do |f|
        if File.directory?(File.join(base, f))
          next if self.dest.sub(/\/$/, '') == File.join(base, f)
          transform_pages(File.join(dir, f))
        else
          first3 = File.open(File.join(self.source, dir, f)) { |fd| fd.read(3) }
          
          if first3 == "---"
            # file appears to have a YAML header so process it as a page
            page = Page.new(self.source, dir, f)
            page.render(self.layouts, site_payload)
            page.write(self.dest)
          else
            # otherwise copy the file without transforming it
            FileUtils.mkdir_p(File.join(self.dest, dir))
            FileUtils.cp(File.join(self.source, dir, f), File.join(self.dest, dir, f))
          end
        end
      end
    end
    
    # The Hash payload containing site-wide data
    #
    # Returns {"site" => {"time" => <Time>, "posts" => [<Post>]}}
    def site_payload
      # Build the category hash map of category ( names => arrays of posts )
      # then sort each array in reverse order
      categories = Hash.new { |hash,key| hash[key] = Array.new } 
      self.posts.each { |p| p.categories.each { |c| categories[c] << p } }
      categories.values.map { |cats| cats.sort! { |a,b| b <=> a} } 
      
      {"site" => {
        "time" => Time.now, 
        "posts" => self.posts.sort { |a,b| b <=> a },
        "categories" => categories
      }}
    end
  end

end
