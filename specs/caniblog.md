# Caniblog: Interoperable Blog Feed Specification

**Version**: 1.0.0
**Status**: Draft
**Created**: February 2026
**Related Specs**: Canipub (books), Canimus (music)

## Overview

Caniblog is a JSON-based feed format for distributing blog posts and articles across federated platforms. It supports:
- **Free content** (public posts)
- **Subscription content** (members-only posts)
- **Paid posts** (one-time purchase to read)
- **Newsletter delivery** (email integration)
- **Series and collections** (multi-part posts)

## Core Principles

1. **Interoperability**: Works across platforms (blogs, wikis, readers)
2. **Multiple formats**: Supports Markdown, HTML, plain text
3. **Federation-ready**: Posts can be shared across communities
4. **Flexible monetization**: Free, subscription, paid, donation-supported
5. **Author control**: Writers own their content and audience
6. **Privacy-first**: No tracking required

## Feed Structure

### Feed Object

```json
{
  "type": "feed",
  "version": "1.0",
  "name": "Blog Name",
  "url": "https://example.com/blog",
  "description": "Blog description or tagline",
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://example.com/author",
    "avatar": "https://example.com/avatar.jpg"
  },
  "language": "en",
  "updated": "2026-02-05T12:00:00Z",
  "links": [
    {
      "rel": "self",
      "type": "application/json",
      "href": "https://example.com/feed.json"
    },
    {
      "rel": "alternate",
      "type": "text/html",
      "href": "https://example.com"
    }
  ],
  "items": [
    // Blog post items (see Post Item below)
  ]
}
```

### Post Item

```json
{
  "type": "post",
  "uid": "unique-post-id",
  "title": "Post Title",
  "slug": "post-title",
  "url": "https://example.com/posts/post-title",

  // Authors (can have multiple)
  "authors": [
    {
      "name": "Primary Author",
      "email": "author@example.com",
      "url": "https://example.com/author",
      "avatar": "https://example.com/avatar.jpg"
    },
    {
      "name": "Co-Author",
      "role": "contributor"
    }
  ],

  // Dates
  "published": "2026-02-05T12:00:00Z",
  "updated": "2026-02-05T14:30:00Z",
  "scheduled": null,

  // Content
  "summary": "A brief excerpt or summary of the post (1-3 sentences)",
  "content": {
    "html": "<p>Full post content in HTML...</p>",
    "markdown": "# Full post content in Markdown...",
    "text": "Plain text version for accessibility"
  },
  "excerpt": "Custom excerpt for sharing and previews",
  "readingTime": "5 min",
  "wordCount": 1247,

  // Organization
  "tags": ["technology", "web", "federation"],
  "categories": ["Web Development"],
  "series": {
    "name": "Building Federated Systems",
    "position": 3,
    "total": 5
  },

  // Media
  "images": {
    "featured": {
      "url": "https://example.com/images/post-hero.jpg",
      "alt": "Description of featured image",
      "width": 1200,
      "height": 630
    },
    "thumbnail": {
      "url": "https://example.com/images/post-thumb.jpg",
      "width": 300,
      "height": 200
    },
    "social": {
      "url": "https://example.com/images/post-og.jpg",
      "width": 1200,
      "height": 630
    }
  },

  // SEO & Social
  "seo": {
    "title": "SEO-optimized title",
    "description": "SEO description (160 chars)",
    "keywords": ["keyword1", "keyword2"]
  },
  "social": {
    "twitter": {
      "card": "summary_large_image",
      "title": "Twitter-specific title",
      "description": "Twitter description"
    },
    "opengraph": {
      "title": "OG title",
      "description": "OG description",
      "type": "article"
    }
  },

  // Access Control
  "status": "published",
  "visibility": "public",
  "access": {
    "model": "free",
    "requiresAuth": false,
    "requiresSubscription": false,
    "price": null
  },

  // Alternative Access Models
  "accessOptions": [
    {
      "model": "free",
      "description": "Free for everyone"
    },
    {
      "model": "subscription",
      "service": "Blog Membership",
      "price": 5.00,
      "interval": "month",
      "description": "Members-only content"
    },
    {
      "model": "purchase",
      "price": 2.99,
      "description": "One-time purchase to read"
    }
  ],

  // Engagement
  "comments": {
    "enabled": true,
    "count": 42,
    "url": "https://example.com/posts/post-title#comments"
  },
  "reactions": {
    "enabled": true,
    "counts": {
      "like": 127,
      "love": 45,
      "insightful": 23
    }
  },
  "stats": {
    "views": 1547,
    "shares": 89
  },

  // Related Content
  "related": [
    {
      "type": "post",
      "uid": "related-post-id",
      "title": "Related Post Title",
      "url": "https://example.com/posts/related"
    }
  ],

  // External Links
  "externalUrl": null,
  "canonicalUrl": "https://example.com/posts/post-title",

  // Licensing
  "license": {
    "name": "CC-BY-SA-4.0",
    "url": "https://creativecommons.org/licenses/by-sa/4.0/"
  },

  // Payees (Optional - Royalty Distribution)
  "payees": [
    {
      "pubKey": "02a1b2c3d4e5f6...",
      "addie-url": "https://addie.planetnine.app",
      "percent": 10,
      "signature": "3045022100..."
    },
    {
      "pubKey": "02f6e5d4c3b2a1...",
      "addie-url": "https://addie.planetnine.app",
      "percent": 90,
      "signature": "3046022100..."
    }
  ],

  // Metadata
  "language": "en",
  "locale": "en-US",
  "updated": "2026-02-05T12:00:00Z"
}
```

## Post Status Values

- `draft` - Not published, work in progress
- `scheduled` - Scheduled for future publication
- `published` - Live and available
- `unlisted` - Published but not in main feed (link-only access)
- `archived` - Old content, marked as archived
- `deleted` - Soft-deleted, may be recoverable

## Visibility Values

- `public` - Visible to everyone
- `unlisted` - Not in feeds but accessible via direct link
- `members` - Only visible to subscribers/members
- `private` - Only visible to author
- `password` - Protected by password

## Access Models

### 1. Free (Public)
```json
{
  "access": {
    "model": "free",
    "requiresAuth": false,
    "price": null
  }
}
```

### 2. Members-Only (Subscription)
```json
{
  "access": {
    "model": "subscription",
    "service": "Blog Membership",
    "requiresSubscription": true,
    "price": 5.00,
    "interval": "month"
  }
}
```

### 3. Paid Post (One-time purchase)
```json
{
  "access": {
    "model": "purchase",
    "price": 2.99,
    "currency": "USD",
    "description": "Premium analysis"
  }
}
```

### 4. Donation-Supported
```json
{
  "access": {
    "model": "donation",
    "suggested": 5.00,
    "minimum": 1.00,
    "description": "Support my writing"
  }
}
```

### 5. Newsletter-Only
```json
{
  "access": {
    "model": "newsletter",
    "requiresEmail": true,
    "description": "Delivered via email"
  }
}
```

## Content Formats

### HTML Content
```json
{
  "content": {
    "html": "<h1>Title</h1><p>Content...</p>",
    "format": "html"
  }
}
```

### Markdown Content
```json
{
  "content": {
    "markdown": "# Title\n\nContent...",
    "format": "markdown"
  }
}
```

### Both Formats
```json
{
  "content": {
    "html": "<h1>Title</h1><p>Content...</p>",
    "markdown": "# Title\n\nContent...",
    "text": "Title\n\nContent...",
    "format": "html"
  }
}
```

## Series and Collections

### Post as Part of Series
```json
{
  "series": {
    "name": "Building in Public",
    "slug": "building-in-public",
    "url": "https://example.com/series/building-in-public",
    "position": 3,
    "total": 10,
    "description": "My journey building a startup"
  }
}
```

### Post in Multiple Collections
```json
{
  "collections": [
    {
      "name": "Best of 2025",
      "slug": "best-of-2025",
      "url": "https://example.com/collections/best-of-2025"
    },
    {
      "name": "Popular Posts",
      "slug": "popular"
    }
  ]
}
```

## Newsletter Integration

```json
{
  "newsletter": {
    "enabled": true,
    "subject": "New Post: {{title}}",
    "preheader": "{{summary}}",
    "sent": "2026-02-05T12:00:00Z",
    "recipients": 1547,
    "opens": 892,
    "clicks": 234
  }
}
```

## Comments and Engagement

### Comments Enabled
```json
{
  "comments": {
    "enabled": true,
    "count": 42,
    "url": "https://example.com/posts/slug#comments",
    "platform": "native", // or "disqus", "commento", etc.
    "requiresAuth": true
  }
}
```

### Reactions
```json
{
  "reactions": {
    "enabled": true,
    "types": ["like", "love", "insightful", "disagree"],
    "counts": {
      "like": 127,
      "love": 45,
      "insightful": 23,
      "disagree": 3
    }
  }
}
```

## Licensing

### Creative Commons
```json
{
  "license": {
    "name": "CC-BY-4.0",
    "url": "https://creativecommons.org/licenses/by/4.0/",
    "allowCommercial": true,
    "allowDerivatives": true,
    "requireAttribution": true
  }
}
```

### All Rights Reserved
```json
{
  "license": {
    "name": "All Rights Reserved",
    "copyright": "© 2026 Author Name"
  }
}
```

## Payee Structure (Optional)

Blog posts can include an optional `payees` array for revenue distribution. Each payee is defined by the Addie four-tuple:

```json
{
  "payees": [
    {
      "pubKey": "02a1b2c3d4e5f6...",
      "addie-url": "https://addie.planetnine.app",
      "percent": 10,
      "signature": "3045022100..."
    },
    {
      "pubKey": "02f6e5d4c3b2a1...",
      "addie-url": "https://addie.planetnine.app",
      "percent": 90,
      "signature": "3046022100..."
    }
  ]
}
```

### Payee Fields

- **pubKey**: Creator's Sessionless public key (secp256k1)
- **addie-url**: Addie payment service URL for processing payments
- **percent**: Percentage of revenue (0-100)
- **signature**: Cryptographic signature of `(pubKey + addie-url + percent)` to verify payee authenticity

### Use Cases

- **Co-author splits**: Primary writer 70%, co-writer 30%
- **Platform revenue**: Writer 80%, platform 20%
- **Referral commissions**: Referrer 5%, writer 95%
- **Guest post splits**: Guest writer 60%, blog owner 40%
- **Subscription splits**: Multiple writers sharing membership revenue

Payees are processed when payment is triggered (paid post purchase, subscription charge, donation) via Addie's payment infrastructure.

## Federation

### Cross-Blog References
```json
{
  "references": [
    {
      "type": "response",
      "url": "https://otherblog.com/original-post",
      "title": "Original Post Title",
      "author": "Other Author"
    },
    {
      "type": "mention",
      "url": "https://thirdblog.com/mentioned-post"
    }
  ]
}
```

### Syndication
```json
{
  "syndication": [
    {
      "platform": "Medium",
      "url": "https://medium.com/@user/post-title",
      "publishedAt": "2026-02-06T10:00:00Z"
    },
    {
      "platform": "Dev.to",
      "url": "https://dev.to/user/post-title",
      "canonical": false
    }
  ]
}
```

## Example: Complete Blog Post

```json
{
  "type": "post",
  "uid": "post-20260205-federated-blogging",
  "title": "The Future of Federated Blogging",
  "slug": "future-of-federated-blogging",
  "url": "https://example.com/posts/future-of-federated-blogging",

  "authors": [
    {
      "name": "Jane Blogger",
      "email": "jane@example.com",
      "url": "https://example.com/about",
      "avatar": "https://example.com/avatar.jpg"
    }
  ],

  "published": "2026-02-05T12:00:00Z",
  "updated": "2026-02-05T14:30:00Z",

  "summary": "Exploring how federated systems are transforming the blogging landscape and giving writers back control of their content.",

  "content": {
    "html": "<h2>Introduction</h2><p>The web is changing...</p>",
    "markdown": "## Introduction\n\nThe web is changing...",
    "format": "markdown"
  },

  "readingTime": "8 min",
  "wordCount": 2147,

  "tags": ["blogging", "federation", "web"],
  "categories": ["Technology"],

  "images": {
    "featured": {
      "url": "https://example.com/images/federated-blog-hero.jpg",
      "alt": "Network of connected blogs",
      "width": 1200,
      "height": 630
    }
  },

  "status": "published",
  "visibility": "public",

  "access": {
    "model": "free"
  },

  "comments": {
    "enabled": true,
    "count": 15
  },

  "license": {
    "name": "CC-BY-SA-4.0",
    "url": "https://creativecommons.org/licenses/by-sa/4.0/"
  },

  "language": "en"
}
```

## Example: Members-Only Post

```json
{
  "type": "post",
  "uid": "post-20260205-premium-analysis",
  "title": "Premium Market Analysis: February 2026",
  "slug": "premium-market-analysis-feb-2026",

  "summary": "In-depth analysis for supporting members only.",

  "status": "published",
  "visibility": "members",

  "access": {
    "model": "subscription",
    "service": "Premium Membership",
    "requiresSubscription": true,
    "price": 10.00,
    "interval": "month"
  },

  "content": {
    "html": "<!-- Full content for members -->",
    "preview": "<p>This post is for members only. Subscribe to read the full analysis.</p>"
  }
}
```

## Feed Filtering

Feeds can be filtered by various criteria:

### By Category
```
GET /feed.json?category=technology
```

### By Tag
```
GET /feed.json?tag=federation
```

### By Author
```
GET /feed.json?author=jane-blogger
```

### By Date Range
```
GET /feed.json?from=2026-01-01&to=2026-01-31
```

### By Access Model
```
GET /feed.json?access=free
GET /feed.json?access=subscription
```

## Comparison with Existing Standards

### vs. RSS/Atom
- **RSS/Atom**: XML-based, limited metadata
- **Caniblog**: JSON-based, rich metadata, multiple access models
- **Compatible**: Caniblog can be converted to RSS/Atom

### vs. JSON Feed
- **JSON Feed**: Simple, focused on syndication
- **Caniblog**: Comprehensive, supports monetization and federation
- **Relationship**: Caniblog extends JSON Feed concepts

### vs. Schema.org BlogPosting
- **Schema.org**: HTML microdata for SEO
- **Caniblog**: API-first feed format
- **Compatible**: Caniblog metadata can be converted to Schema.org

## Migration from Existing Platforms

### From WordPress
```javascript
// Map WordPress post to Caniblog
{
  uid: post.id,
  title: post.title.rendered,
  slug: post.slug,
  content: {
    html: post.content.rendered,
    format: "html"
  },
  published: post.date,
  updated: post.modified,
  authors: [{ name: post.author_name }],
  tags: post.tags.map(t => t.name),
  categories: post.categories.map(c => c.name),
  images: {
    featured: { url: post.featured_media_url }
  }
}
```

### From Medium
```javascript
// Map Medium post to Caniblog
{
  uid: post.id,
  title: post.title,
  content: {
    html: post.content.bodyModel.html
  },
  published: post.createdAt,
  authors: [{ name: post.creatorName }],
  tags: post.virtuals.tags.map(t => t.name),
  readingTime: post.virtuals.readingTime + " min",
  stats: {
    views: post.virtuals.totalClapCount
  }
}
```

### From Substack
```javascript
// Map Substack post to Caniblog
{
  uid: post.id,
  title: post.title,
  content: {
    html: post.body_html
  },
  published: post.post_date,
  access: {
    model: post.audience === "everyone" ? "free" : "subscription"
  },
  newsletter: {
    enabled: true,
    recipients: post.email_sent_count
  }
}
```

## Implementation Notes

### For Bloggers
1. Generate Caniblog feeds for your blog
2. Host at `/feed.json` or `/caniblog.json`
3. Update feed when posts are published/modified
4. Include access control for premium content
5. Support federation via cross-blog references

### For Platforms
1. Parse Caniblog feeds from blogs
2. Display posts with accurate metadata
3. Respect access control and monetization
4. Support comments and engagement
5. Enable federation features

### For Readers
1. Subscribe to Caniblog feeds
2. Aggregate posts across multiple blogs
3. Support authors via subscriptions or purchases
4. Engage with comments and reactions
5. Discover related content via federation

## Future Extensions

Planned additions:
- **Podcast episodes** (audio posts with transcripts)
- **Video posts** (embedded video with captions)
- **Photo essays** (image-heavy posts)
- **Link posts** (curated links with commentary)
- **Question posts** (Q&A format)
- **Event posts** (meetups, webinars)

## Resources

- [JSON Feed Specification](https://jsonfeed.org/)
- [RSS 2.0 Specification](https://www.rssboard.org/rss-specification)
- [Atom Specification](https://www.ietf.org/rfc/rfc4287.txt)
- [Schema.org BlogPosting](https://schema.org/BlogPosting)
- [Canipub (Books)](./canipub.md)
- [Canimus (Music)](./canimus.md)

## Contributing

Caniblog is an open specification. Contributions welcome:
- GitHub: [freyja-love-and-magic/caniblog](https://github.com/freyja-love-and-magic/caniblog)
- Issues: Feature requests and bug reports
- Discussions: Best practices and implementations

---

**Caniblog**: Blogs for communities, not corporations.

**Built with 💚 for The Advancement**
