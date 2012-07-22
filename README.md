# Chef Bootstrap Repo

## Features

* Convenient bootstrap script for optimal first-run experience and incremental
  project updates
* Flexible knife.rb configuration that supports solo, hosted and open source
  Chef via environment variable injection
* [direnv](https://github.com/zimbatm/direnv) support which loads and unloads
  `bin/` and `script/` from your `PATH`

## Development

### Development Setup

Setting up for development should *only* require the following:

    git clone <git_url>
    cd <repo-dir>
    ./script/bootstrap

### Refreshing/Updating Local Copy

Similiar to the **Development Setup**:

    git pull
    ./script/bootstrap

## <a name="development"></a> Development

* Source hosted at [GitHub][repo]
* Report issues/questions/feature requests on [GitHub Issues][issues]

Pull requests are very welcome! Make sure your patches are well tested.
Ideally create a topic branch for every separate change you make. For
example:

1. Fork the repo
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## <a name="authors"></a> Authors

Created and maintained by [Fletcher Nichol][fnichol] (<fnichol@nichol.ca>)

[fnichol]:      https://github.com/fnichol
[repo]:         https://github.com/fnichol/chef-bootstrap-repo
[issues]:       https://github.com/fnichol/chef-bootstrap-repo/issues
[contributors]: https://github.com/fnichol/chef-bootstrap-repo/contributors
