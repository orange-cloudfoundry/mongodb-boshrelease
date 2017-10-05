Setup your Ruby Environment
===========================

You'll need `chruby`, and a `ruby` that is local to your user home directory.


Install `chruby`
----------------

On macOS, it's easy. Jsut `brew install chruby` and you're done.

On Ubuntu Linux, there's sadly no automated installer. You'll have to run the
manual install process, as describe in the [Install](chruby-install) section
of [chruby](chruby-repo).

In both cases, you'll need to tweak your `~/.bashrc` as described in the
[Auto-Switching](chruby-auto-switching) section.

[chruby-repo](https://github.com/postmodern/chruby)
[chruby-install](https://github.com/postmodern/chruby#install)
[chruby-auto-switching](https://github.com/postmodern/chruby#auto-switching)


Install `ruby-build`
--------------------

Again it's easy on macOS with `brew install ruby-build` and your get a recent
version that allows you to build recent ruby versions.

On Ubuntu Linux, that's sightly more complicated because Aptitude repositories
provide versions of `ruby-build` that are so old that it makes it pointless.

So, you'd better off with installing `ruby-build` yourself. (This could be
done as a `rbenv` plugin, but we use `chruby` instead for its improvements
over `rbenv`.) So we default to installing `ruby-build` as a standalone
program, which is the 3rd option of the [Installation](ruby-build-install)
process.

	cd /opt
	git clone https://github.com/rbenv/ruby-build.git
	PREFIX=/usr/local ./ruby-build/install.sh

[ruby-build-install](https://github.com/rbenv/ruby-build#installation)


Create your Ruby environment
----------------------------

Build your version of Ruby. Check the version mentionned in the `.ruby-version`
file at the root of your project working tree.

	ruby-build 2.4.2 --install-dir ~/.rubies/ruby-2.4.2

Once done, you get your own separate Gem repository for this Ruby version, but
you need to update this Gem system.

	gem update --system

Then you can download the Gems that are required for your project, as
expressed in the `Gemfile`. For this, you first need `bundler`.

	gem install bundler

Now you can download your project specific Gems.

	bundle install

And you're done. Now you are ready to run your own ruby scripts!
