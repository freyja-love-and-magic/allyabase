# Canipub: Interoperable Book Feed Specification

**Version**: 1.0.0
**Status**: Draft
**Created**: February 2026
**Based on**: Canimus (music feeds), ONIX standards, book metadata best practices

## Overview

Canipub is a JSON-based feed format for distributing books across federated platforms. It supports:
- **Commercial sales** (one-time purchases)
- **Subscription reading** (like Kindle Unlimited)
- **Free/open access** (public domain, Creative Commons)

## Core Principles

1. **Interoperability**: Works across platforms (web, apps, e-readers)
2. **Flexibility**: Supports multiple business models
3. **Standards-compliant**: Uses ISBN, BISAC, ONIX conventions
4. **Federation-ready**: Books can be shared across communities
5. **DRM-optional**: Publishers control access policies

## Feed Structure

### Feed Object

```json
{
  "type": "feed",
  "version": "1.0",
  "name": "Publisher Name or Collection Title",
  "url": "https://example.com/feeds/books/publisher-id",
  "description": "Feed description",
  "language": "en",
  "updated": "2026-02-05T12:00:00Z",
  "links": [
    {
      "rel": "self",
      "type": "application/json",
      "href": "https://example.com/feeds/books/publisher-id"
    },
    {
      "rel": "alternate",
      "type": "text/html",
      "href": "https://example.com/publisher-id"
    }
  ],
  "items": [
    // Book items (see Book Item below)
  ]
}
```

### Book Item

```json
{
  "type": "book",
  "uid": "unique-book-id",
  "isbn": "9781234567890",
  "isbn10": "1234567890",
  "asin": "B00EXAMPLE",

  // Core Metadata
  "name": "Book Title: Subtitle",
  "authors": [
    {
      "name": "Author Name",
      "role": "author",
      "url": "https://example.com/authors/author-id"
    },
    {
      "name": "Illustrator Name",
      "role": "illustrator"
    }
  ],
  "publisher": "Publisher Name",
  "imprint": "Imprint Name",
  "published": "2025-03-15",
  "language": "en",

  // Content Description
  "summary": "Short description (1-3 sentences)",
  "description": "Full description with rich text/HTML",
  "excerpt": "First chapter or preview text...",
  "tableOfContents": "Chapter 1: Introduction\nChapter 2: ...",
  "keywords": ["fiction", "mystery", "thriller"],

  // Classification
  "bisac": [
    {
      "code": "FIC022000",
      "name": "FICTION / Mystery & Detective / General"
    }
  ],
  "genres": ["Mystery", "Thriller"],
  "audience": {
    "ageRange": "18+",
    "gradeRange": "Adult"
  },

  // Physical Details
  "format": "paperback",
  "pageCount": 352,
  "weight": "400g",
  "dimensions": {
    "height": "198mm",
    "width": "129mm",
    "spine": "25mm"
  },

  // Digital Details (for ebooks/audiobooks)
  "fileSize": "2.5MB",
  "runtime": "8h 45m",

  // Editions & Versions
  "edition": "2nd Edition",
  "version": "1.0",
  "seriesInfo": {
    "seriesName": "Detective Series",
    "volume": 3,
    "totalVolumes": 5
  },

  // Images
  "images": {
    "cover": {
      "url": "https://example.com/covers/book-id.jpg",
      "width": 1600,
      "height": 2400
    },
    "thumbnail": {
      "url": "https://example.com/covers/book-id-thumb.jpg",
      "width": 200,
      "height": 300
    }
  },

  // Content Files
  "content": [
    {
      "type": "application/epub+zip",
      "url": "https://example.com/files/book-id.epub",
      "size": 2621440,
      "drm": false
    },
    {
      "type": "application/pdf",
      "url": "https://example.com/files/book-id.pdf",
      "size": 3145728,
      "drm": false
    },
    {
      "type": "application/x-mobipocket-ebook",
      "url": "https://example.com/files/book-id.mobi",
      "size": 2097152,
      "drm": false
    }
  ],

  // Pricing & Availability
  "availability": "available",
  "access": {
    "model": "purchase",
    "price": 14.99,
    "currency": "USD",
    "territories": ["US", "CA", "GB"],
    "expires": null
  },

  // Alternative Access Models
  "accessOptions": [
    {
      "model": "purchase",
      "price": 14.99,
      "currency": "USD",
      "description": "Buy and own forever"
    },
    {
      "model": "subscription",
      "service": "BookPass Unlimited",
      "price": 0,
      "requiresSubscription": true,
      "description": "Read with subscription"
    },
    {
      "model": "rental",
      "price": 2.99,
      "duration": "30 days",
      "description": "Rent for 30 days"
    },
    {
      "model": "free",
      "price": 0,
      "license": "CC-BY-NC-SA-4.0",
      "description": "Free under Creative Commons"
    }
  ],

  // Physical Inventory (for print books)
  "inventory": {
    "available": true,
    "quantity": 150,
    "condition": "new",
    "conditionNotes": ""
  },

  // Reviews & Social Proof
  "rating": {
    "average": 4.5,
    "count": 1247
  },
  "reviews": [
    {
      "source": "New York Times",
      "quote": "A thrilling page-turner!",
      "url": "https://nytimes.com/review"
    }
  ],

  // Related Works
  "related": [
    {
      "type": "sequel",
      "isbn": "9781234567891",
      "name": "Book Title 2"
    },
    {
      "type": "audiobook",
      "isbn": "9781234567892",
      "name": "Book Title (Audio Edition)"
    }
  ],

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
  "updated": "2026-02-05T12:00:00Z",
  "url": "https://example.com/books/book-id"
}
```

## Access Models

### 1. Purchase (One-time)
```json
{
  "access": {
    "model": "purchase",
    "price": 14.99,
    "currency": "USD",
    "territories": ["WORLD"]
  }
}
```

### 2. Subscription (Read with membership)
```json
{
  "access": {
    "model": "subscription",
    "service": "BookPass Unlimited",
    "requiresSubscription": true,
    "price": 0
  }
}
```

### 3. Rental (Temporary access)
```json
{
  "access": {
    "model": "rental",
    "price": 2.99,
    "duration": "30 days",
    "expires": "2026-03-05T12:00:00Z"
  }
}
```

### 4. Free (Public domain or Creative Commons)
```json
{
  "access": {
    "model": "free",
    "price": 0,
    "license": "public-domain"
  }
}
```

### 5. Library (Borrowing with limits)
```json
{
  "access": {
    "model": "library",
    "service": "Community Library",
    "duration": "14 days",
    "waitlist": 3,
    "copies": 5
  }
}
```

## Book Formats

Supported `format` values:
- `hardcover`
- `paperback`
- `mass-market-paperback`
- `ebook`
- `audiobook`
- `board-book`
- `spiral-bound`
- `leather-bound`

## Content Types (MIME)

Supported `content[].type` values:
- `application/epub+zip` - EPUB format
- `application/pdf` - PDF format
- `application/x-mobipocket-ebook` - MOBI/AZW format
- `application/vnd.amazon.ebook` - KF8/AZW3 format
- `audio/mpeg` - Audiobook MP3
- `audio/mp4` - Audiobook M4A/M4B
- `text/html` - Web-based reading

## Availability Status

Supported `availability` values:
- `available` - In stock and ready
- `pre-order` - Available for pre-order
- `out-of-print` - No longer being printed
- `out-of-stock` - Temporarily unavailable
- `coming-soon` - Not yet released
- `discontinued` - Permanently unavailable

## Book Conditions

For physical books, `inventory.condition`:
- `new` - Brand new
- `like-new` - Excellent condition
- `very-good` - Minor wear
- `good` - Normal wear
- `acceptable` - Heavy wear but readable

## BISAC Codes

Use standard BISAC Subject Codes:
```json
{
  "bisac": [
    {
      "code": "FIC022000",
      "name": "FICTION / Mystery & Detective / General"
    }
  ]
}
```

Common BISAC categories:
- **FIC** - Fiction
- **JUV** - Juvenile (Children's)
- **YAF** - Young Adult Fiction
- **BIO** - Biography & Autobiography
- **HIS** - History
- **SCI** - Science
- **REL** - Religion

Full list: https://bisg.org/page/BISACSubjectCodes

## Licensing & DRM

### Creative Commons
```json
{
  "access": {
    "model": "free",
    "license": "CC-BY-SA-4.0"
  }
}
```

Supported licenses:
- `CC-BY-4.0`
- `CC-BY-SA-4.0`
- `CC-BY-NC-4.0`
- `CC-BY-NC-SA-4.0`
- `CC0-1.0`
- `public-domain`

### DRM Status
```json
{
  "content": [
    {
      "type": "application/epub+zip",
      "url": "https://example.com/book.epub",
      "drm": false,
      "drmScheme": null
    }
  ]
}
```

## Federation & Discovery

### Cross-platform References
```json
{
  "externalIds": {
    "isbn": "9781234567890",
    "isbn10": "1234567890",
    "asin": "B00EXAMPLE",
    "oclc": "123456789",
    "lccn": "2025012345",
    "doi": "10.1234/example",
    "googleBooksId": "abc123"
  }
}
```

### Federated Availability
Books can be available from multiple sources:
```json
{
  "sources": [
    {
      "name": "Publisher Direct",
      "url": "https://publisher.com/book",
      "price": 14.99,
      "format": "epub"
    },
    {
      "name": "Community Library",
      "url": "https://library.community/book",
      "access": "library",
      "waitlist": 2
    }
  ]
}
```

## Example: Complete Book Entry

```json
{
  "type": "book",
  "uid": "book-12345",
  "isbn": "9781234567890",
  "name": "The Federated Future: A Guide to Decentralized Publishing",
  "authors": [
    {
      "name": "Jane Publisher",
      "role": "author"
    }
  ],
  "publisher": "Community Press",
  "published": "2026-01-15",
  "language": "en",
  "summary": "An exploration of how federated systems transform publishing.",
  "description": "<p>This groundbreaking book explores...</p>",
  "bisac": [
    {
      "code": "COM000000",
      "name": "COMPUTERS / General"
    }
  ],
  "format": "ebook",
  "pageCount": 284,
  "images": {
    "cover": {
      "url": "https://publisher.com/covers/book-12345.jpg"
    }
  },
  "content": [
    {
      "type": "application/epub+zip",
      "url": "https://publisher.com/files/book-12345.epub",
      "drm": false
    }
  ],
  "accessOptions": [
    {
      "model": "purchase",
      "price": 9.99,
      "currency": "USD"
    },
    {
      "model": "subscription",
      "service": "ReadPass",
      "requiresSubscription": true
    },
    {
      "model": "free",
      "license": "CC-BY-SA-4.0",
      "description": "Free for personal use"
    }
  ],
  "url": "https://publisher.com/books/federated-future"
}
```

## Implementation Notes

### For Publishers
1. Generate Canipub feeds for your catalog
2. Host at predictable URLs (`/feeds/books/publisher-id`)
3. Update feeds when books are added/modified
4. Include multiple access options when available
5. Use standard ISBNs and BISAC codes

### For Platforms
1. Parse Canipub feeds from publishers
2. Display books with accurate metadata
3. Support multiple access models (purchase, subscription, free)
4. Link to source platforms for fulfillment
5. Respect DRM and licensing terms

### For Readers
1. Subscribe to feeds from favorite publishers
2. Aggregate books across multiple sources
3. Choose preferred access method (buy, borrow, subscribe)
4. Download in preferred format (EPUB, PDF, MOBI)
5. Read on any compatible device

## Comparison with Existing Standards

### vs. ONIX
- **ONIX**: XML-based, comprehensive, industry standard
- **Canipub**: JSON-based, web-friendly, federation-focused
- **Use case**: Canipub for web/API distribution, ONIX for B2B metadata exchange

### vs. Schema.org Book
- **Schema.org**: HTML microdata for SEO
- **Canipub**: Structured feeds for distribution
- **Compatible**: Canipub metadata can be converted to Schema.org

### vs. Canimus (Music)
- **Canimus**: RSS-based audio feeds
- **Canipub**: JSON-based book feeds
- **Shared**: Federation model, multiple access options

## Migration from Existing Formats

### From Amazon Listings
Map these fields:
- `item-name` → `name`
- `product-id` → `isbn` or `asin`
- `price` → `access.price`
- `item-condition` → `inventory.condition`
- `item-note` → `inventory.conditionNotes`

### From ONIX
Canipub supports most ONIX fields. Common mappings:
- `<ProductIdentifier>` → `isbn`, `asin`
- `<TitleDetail>` → `name`
- `<Contributor>` → `authors[]`
- `<Subject>` → `bisac[]`, `keywords[]`
- `<SupplyDetail>` → `access`, `inventory`

## Payee Structure (Optional)

Books can include an optional `payees` array for royalty distribution. Each payee is defined by the Addie four-tuple:

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

- **Author royalties**: Primary author gets 90%, co-author gets 10%
- **Platform splits**: Author 70%, platform 30%
- **Affiliate commissions**: Recommender 10%, author 90%
- **Charity splits**: Author 50%, charity 50%

Payees are processed when payment is triggered (purchase, subscription charge, etc.) via Addie's payment infrastructure.

## Future Extensions

Planned additions:
- **Audiobook metadata** (narrator, duration, chapters)
- **Textbook features** (ISBN editions, course adoption)
- **Academic metadata** (peer review, citations)
- **Manga/Comics** (reading direction, colorization)
- **Multi-volume works** (box sets, anthologies)

## Resources

- [BISAC Subject Codes](https://bisg.org/page/BISACSubjectCodes)
- [ONIX Specification](https://www.editeur.org/83/Overview/)
- [ISBN International](https://www.isbn-international.org/)
- [Creative Commons Licenses](https://creativecommons.org/licenses/)
- [Canimus (Music Feeds)](https://github.com/PlaidWeb/Canimus)

## Contributing

Canipub is an open specification. Contributions welcome:
- GitHub: [freyja-love-and-magic/canipub](https://github.com/freyja-love-and-magic/canipub)
- Issues: Feature requests and bug reports
- Discussions: Best practices and use cases

---

**Canipub**: Books for communities, not corporations.

**Built with 💚 for The Advancement**
