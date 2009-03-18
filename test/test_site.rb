require File.dirname(__FILE__) + '/helper'

class TestSite < Test::Unit::TestCase
  context "creating sites" do
    setup do
      stub(Jekyll).configuration do
        Jekyll::DEFAULTS.merge({'source' => source_dir, 'destination' => dest_dir})
      end
      @site = Site.new(Jekyll.configuration)
    end

    #should "read layouts" do
      #@s.read_layouts
      #assert_equal ["default", "simple"].sort, @s.layouts.keys.sort
    #end

    #should "read posts" do
      #@s.read_posts('')
      #posts = Dir[File.join(@source, '_posts/*')]
      #assert_equal posts.size - 1, @s.posts.size
    #end

    #should "deploy payload" do
      #clear_dest
      #@s.process

      #posts = Dir[File.join(@source, "**", "_posts/*")]
      #categories = %w(bar baz category foo z_category publish_test).sort

      #assert_equal posts.size - 1, @s.posts.size
      #assert_equal categories, @s.categories.keys.sort
      #assert_equal 3, @s.categories['foo'].size
    #end

    should "filter entries" do
      ent1 = %w[foo.markdown bar.markdown baz.markdown #baz.markdown#
              .baz.markdow foo.markdown~]
      ent2 = %w[.htaccess _posts bla.bla]

      assert_equal %w[foo.markdown bar.markdown baz.markdown], @site.filter_entries(ent1)
      assert_equal ent2, @site.filter_entries(ent2)
    end
  end
end
