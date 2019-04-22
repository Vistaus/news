struct FeedItem {
    string? title;
    string? about;
    string? link;
    DateTime? pubDate;
    string? content;
}

abstract class Feed {
    [Description(nick = "Feed items", blurb = "This is the list of feed entries.")]
    public abstract FeedItem[] items { get; protected set; }
    [Description(nick = "Feed title", blurb = "This is the title of the feed.")]
    public abstract string? title { get; protected set; }
    [Description(nick = "Feed link", blurb = "The website of the news source.")]
    public abstract string? link { get; protected set; }
    [Description(nick = "Feed information", blurb = "This is the description of the feed.")]
    public abstract string? about { get; protected set; }
    [Description(nick = "Copyright", blurb = "This is the copyright information of the feed.")]
    public abstract string? copyright { get; protected set; }
    [Description(nick = "Feed source", blurb = "This is the source of the feed.")]
    public abstract string source { get; protected set; }
}

errordomain FeedError {
    INVALID_DOCUMENT
}

class RssFeed : Feed {
    public override string? copyright { get; protected set; default = null; }
    public override string? about { get; protected set; default = null; }
    public override string? title { get; protected set; default = null; }
    public override string? link { get; protected set; default = null; }
    public override FeedItem[] items { get; protected set; default = new FeedItem[0]; }

    public override string source { get; protected set; }

    private RssFeed() {}

    /* Creates feed from xml */
    public RssFeed.from_xml(string str) throws Error {
        var doc = Xml.Parser.parse_doc(str);
    
        Xml.Node* root = doc->get_root_element();
        if(root == null) {
            throw new FeedError.INVALID_DOCUMENT("no root element");
        }

        // find channel element
        var channel = root->children;
        for(; channel->name != "channel"; channel = channel->next);

        FeedItem[] items = this.items;

        // loop through elements
        for(var child = channel->children; child != null; child = child->next) {
            switch(child->name) {
            case "title":
                this.title = child->get_content();
                break;
            case "description":
                this.about = child->get_content();
                break;
            case "link":
                this.link = child->get_content();
                break;
            case "copyright":
                this.copyright = child->get_content();
                break;
            case "item":
                FeedItem item = FeedItem();
                for(var childitem = child->children; childitem != null; childitem = childitem->next) {
                    switch(childitem->name) {
                    case "title":
                        item.title = childitem->get_content().replace("&", "&amp;");
                        break;
                    case "link":
                        item.link = childitem->get_content();
                        break;
                    case "description":
                        item.about = childitem->get_content();
                        if(item.about.length == 0)
                            item.about = null;
                        break;
                    case "encoded":
                        item.content = childitem->get_content();
                        break;
                    case "pubDate":
                        item.pubDate = parse_rfc822_date(childitem->get_content());
                        break;
                    }
                }

                items += item;
                break;
            }
        }
        this.items = items;
    }

    /* Creates feed from file */
    public RssFeed.from_file(File file) throws Error {
        DataInputStream data_stream = new DataInputStream(file.read());

        string line = null;
        var text = new StringBuilder();
        while((line = data_stream.read_line()) != null) {
            text.append(line);
            text.append_c('\n');
        }

        this.from_xml(text.str);
    }

    /* Creates feed from uri */
    public RssFeed.from_uri(string uri) throws Error {
        this.from_file(File.new_for_uri(uri));
        this.source = uri;
    }
}

class GoogleNewsFeed : RssFeed {
    private string query = null;

    public GoogleNewsFeed() throws Error {
        base.from_uri("https://news.google.com/news/rss/?ned=us&gl=US&hl=e");
    }

    public GoogleNewsFeed.with_search(string q) throws Error {
        base.from_uri("https://news.google.com/news/rss/search/section/q/" + q + "?ned=us&gl=US&hl=en");
        this.query = q;
    }

    private string _title;
    public override string? title {
        get {
            if(this.query == null) {
                return "Google News";
            } else {
                _title = "\"" + this.query + "\" - Google News";
                return _title;
            }
        }
        protected set {}
    }

    public override string? link { get { return "https://news.google.com/"; } protected set{} }
}

