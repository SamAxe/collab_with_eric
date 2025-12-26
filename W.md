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


# Farm centric vs site centric

After following FedWiki for a while now, it seems quite obvious that a farm centric server offers a lot of benefits over site centric.  It takes possibly a very significant step away
from decentralization in that it manages resources with a farm perspective rather than a site perspective.[^30]  Specifically, a farm would manage access at a farm level and there could
be light access controls such that more than one owner could update pages, an access controlled group could work together on common parts, etc.[^31]


[^30]:  I'm thinking that site specific could be entirely client driven with a remote value store...the implementation all have a thin server anyway, so if there is a server, maybe
        this isn't such a large step.
[^31]:  I think one of the key deficiencies of current fedwiki (in total contrast to original wiki) is that there is no share space in time and place.  A farm could enable this while
        still keeping tight control of moderation issues that caused the ultimate demize of original wiki.


# Farm as a server

Not fully thought though, but I think that `example.com/site1` plays better with the internet than `site1.example.com` does.  I think this would also impact how assets are referred to and would
help with being able to export/import sites.


# Farm as aggregator vs Farm as a producer

I think there would be atleast two types of farms, and both would export similar interfaces, so hopefully can be seen externally somewhat interchangeably.

A producing farm would host the sites, pages, assets and owners of the sites would control the writing to those pages.

An aggregating farm would poll and pull content from producing farms (or other aggregating farms).  It might provide aggregated search, backup, caching, etc type services but wouldn't have
and content in the way that a producing farm does.

# Rendering and resolution context and time

Setting aside specific implementation details, a story is a list of paragraphs.

One question is whether the paragraphs should know that they are in a list with other paragraphs and therefore
able to influence, or be influenced by, the other paragraphs.

Another question, viewing the story as a container of items, is nesting containers allowed and does it make sense?  For example,
a story inside a story might be a section and the title would be a section heading then.

Many protocols have a `.text` field that the user wrote and a `.rendered` field that caches whatever rendering happened, so that future rendering can use the cached values.  (This might address some of the container in container concerns...)

# The uniqueness of paragraph id's

What does a paragraph id mean?  Is it 1:1 replacement for a given version of text e.g. each version of text would have a unique `para.id`, or a tag for a container that holds text.  Currently, some differencing views use
paragraphs with same id as a weak association that the paragraph was copied from another page.  Or some blessed paragraph id's are used to represent specific content across sites.  (I think there are stronger mechanisms to
achieve that function, but defer to later.)

One view could be that a `(site,para.id)` is unique, that is the `para.id` uniqness is constrained to be within a site.  Another view is that `para.id` is globally unique.

I tend to think that the first view has less surprises, but I think that does preclude some of the current implemented functionality with twin pages.


# Should the client be a webapp?

One of the desired properties is that the content is accessible over many decades.

# A database schema with topics and posts

A topic would start the beginning of a conversation (internally the head of linked list of posts).  The conversation would be a _new_ conversation or split from another conversation.
I think there is a lot of similarity to topic is like a page and the conversation is like the items in the story.

## `reply-to`

Structurally, a page has a `title` and `story` and the `story` is a list of `items` (e.g. text paragraphs) (and ignoring the journal for now).  Each `item` has an `id`.  The order of
the items in the story is the same as the order in the array.  If the item had a `reply-to-id` field, then this forms a linked list and effectively
is the same data structure.

A thought I had is that the difference between a tree and linked list is the number of items that refer to an `item.id`.  A tree is what is needed to
have a _conversation_ style flow which would allow comments on an item to be shown on a common view.[^20]

[^20]:  Definately some details to work out, regarding the uniqueness of `id`'s and how items from different sites would be mixed into a shared view this way.


### topics table (from Discourse via chatgpt)

  * id
  * title
  * archetype (regular or private_message, maybe page too)
  * category_id
  * created_at, last_update, created_by

### posts table

  * id
  * user_id
  * topic_id
  * post_number
  * raw
  * cooked
  * reply_to_post_number
  * created_at, updated_at
  * deleted_at (soft delete)

### post_custom_fields

Would be a table for adding arbitrary json for items where `text` isn't enough, for example.

### post revisions table

The update history, but posts table always has the most recent version, so history is consulted and versions are reconstructed on request.

### REST

Instead of REST with returning json data, we'll use HTMX, but will still need basic sorts of things.


GET    /topics/latest
       limit=
       before=<timestamp|topic_id>
       category_id

Get    /topic/{topic_id}
GET    /topics/{topic_id}/posts?after=50&limit=20

POST   /topics
POST   /topics/{topic_id}/posts   create a post
PUT    /posts/{post_id}            edit a post
GET    /posts/{post_id}/revisions  history
DELETE /posts/{post_id}         moderation/soft delete


### search

Needs to be here, probably support for #tags

### item widget

  * Maybe toggle with whether to render as a container or as individual items.
  * "insert from assets" type option.
  * drag/drop/move, but maybe is context dependent
  * container could be a story or a conversation and default semantics appropriate for either one.
  * create, read, update, delete
  * Maybe some strategy for changing the kind of item or kind of container.


### Neighborhood

  Not sure how neighborhood will manifest itself.  Might be different for the value creation farm vs an aggregator farm.

### Markdown

Text will be markdown centric.
Unsure how much extended markdown will be supported initially. (e.g. paniolo support may be a superset of many of the plugins)

### Things not included from current FW

  * For version 1, I don't care about the lineup or lineup semantics


# Other

## Licensing

There are bots, scrapers, etc...not sure if it makes sense for licenses to be per page/conversation or for the entire site or farm.
