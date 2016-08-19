# bundle-bungler

This is barely a thing, and a weird thing at that.

In my current role as Application SRE Manager @ LivingSocial, my team is responsible for over 100 sites/services, most
of them Ruby/Rails. Many versions of Rails in flight, many versions of Ruby in flight. 

When I was a more focused developer here, a few to a dozen sites/services, it wasn't a big deal to just keep the gems
installed locally per-project. `bundle install --path zz` was my cargo-culted behavior, to get gems browseable in older 
versions of RubyMine. (.bundle wasn't a good location as RM ignored these dirs, zz pushed search results in gem sources
to the end of lists, RM didn't work well with gemsets or non-local gem installs, etc.)

Now pulling and installing the same gems over and over again across 100+ projects was a time suck. 

Installing all of the gems to an unpathed Bundler location, i.e. with the Ruby install (I'm an rbenv-er), was better, 
but still would result in a lot of duplication between release versions of Ruby, and we had plenty of apps spread 
across 2.3.0 and 2.3.1, and 2.2.2 and 2.2.3 and 2.2.4. I don't want 3 copies of nokogiri and libv8 for 2.2.x apps when
I could have just one, nor do I want to wait the time to rebuild these long building things because I have things to do.

When Bundler installs to a specific path, it creates a directory structure that shares gems across the same minor
version of Ruby:

    $ ls ~/.bundle/ruby/
    1.9.1   2.1.0   2.2.0   2.3.0

I created a simple shell script to run from any project dir to remove any existing --path settings and re-install 
everything to ~/.bundle, [unset_local_bundle.sh](unset_local_bundle.sh).
 
After a while though, this seemed to bog down RubyMine when I needed to dig around the contents of a specific project
(or when I'd hit this 'bug' - https://youtrack.jetbrains.com/issue/RUBY-18274), so I created a shell script to toggle
things back, [set_local_bundle.sh](set_local_bundle.sh).
 
But, this gets me right back to the original problem, which is this can take a looong time to run sometimes, since I'm
having to re-install every gem, and when nokogiri and libv8 and others hit, I'm waiting for 15-20 minutes sometimes.

And my brain is thinking - all of these gems are built and sitting in my home directory already, would it be faster to
just copy all of those files to my local `--path`? 

It's not lightning fast, but it's frequently 2-4x times faster than just re-installing all of the gems, 
[rbset_local_bundle.rb](rbset_local_bundle.rb).

(What if I just symlinked ... ?)
