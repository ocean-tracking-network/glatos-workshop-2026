# Dockerfile
FROM ruby:2.7

# Update RubyGems so ffi can install cleanly, and pin Bundler to match your lockfile
RUN gem update --system 3.3.22 && gem install bundler:1.17.3 -N

WORKDIR /srv/jekyll
EXPOSE 4000 35729

# Use the gems specified by the repo (github-pages brings jekyll 3.9.x)
CMD bash -lc "bundle _1.17.3_ install && bundle _1.17.3_ exec jekyll serve --host 0.0.0.0 --livereload"
