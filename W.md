Some thoughts about some [Fed]wiki features and maybe how to go about them.


# Page titles/slugs/renames.

The **current situation** is that titles are converted to slugs where slugs are lowercase and ascii.[^1]  This means that 
unicode and symbols are removed and don't differentiate pages.  The `slug` is the permanent name for a given page that will
appear in a permalink and needs to be compatible with URL/URI.

The basic gist of a solution is, the current `asSlug(unicode title) -> string` function can be the basis, but on page creation, if the page already exists in that site,
then there needs to be a `_n` appended to the generated slug.  The unicode title and generated slug pair need to be stored somewhere,
(in the page.json or in a database table).  All future slug resolution[^2] needs to use this pairing for resolving the slugname.  Any input to the user needs to present
the unicode title.

The invariants in the above is a page is created and assinged, a unique to the site, slug that never changes.

A page title can change or be updated.  (There is a set of follow-on issues about what to do to existing links.[^3])

## issues as a result of this approach

* Any pages that refer to the old title are likely to be unresolved or if a new page with that title appears, will be misassociated.[^4]
* A choice will have to be made about whether to keep aliases or not.
* 



[^1]:  The conversion is 3 steps.  
       1) convert all spaces, ` `, to dashes, '-'.  
       2) remove all characters not in `A-Z`, `a-z`, `0-9`, or a `-`.  
       3) convert to lowercase

[^2]:  E.g. [[wikilinks]], or any other place the currently calls `asSlug`.
[^3]:  For many cases, my opinion is quite similar to `git`'s take when `--force` commiting, that if you rewrite
       history in a public repository, you assume all the consequences of impact that has.

       There could certainly be features to ease the burden of unresolved titles, maybe by keeping the old page name as
       an alias, etc, though that trade-off conflicts with being able to reused the title, if that was the motivation for
       renaming the page to begin with.

[^4]:  Though I think this is the case for today too, if a page is deleted and then created again and is more a ramification of
       dynamically resolving titles at click time through a name lookup than as a result of this specific approach to resolving a title.


# Moving a site

In concept, it should be trivial to move a site from one host/farm to another host/farm (maybe including a site rename, but separate question for now).
For the most part, an `export.json` file that contains all the sites's pages works as you'd expect.  The `assets` are where the current issues[^10] are.

[^10]:  I don't recall the specific issues, so this is a todo for later.
