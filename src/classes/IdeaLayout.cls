global virtual with sharing class IdeaLayout extends cms.ContentTemplateController {
    public String getIdeaListHtml() {
        String idPrefix = this.getContentLayoutInstanceId();
        String categorySelectorId = idPrefix + '-category';
        String statusSelectorId = idPrefix + '-status';
        String searchTextId = idPrefix + '-search';

        String detailUrlCsv = '';
        if(detailUrl != null) {
            detailUrlCsv = detailUrl.csv;
        }

        String html = '';

        html += '<section id="' + idPrefix + '" data-idealist data-zoneid="' + zoneId + '"'
            + ' data-categories="' + categories.escapeHtml4() + '"'
            + ' data-pagesize="' + pageSize + '"'
            + ' data-iscurrentuser="' + isCurrentUser + '"'
            + ' data-detailurlcsv="' + detailUrlCsv + '"'
            + ' data-pointslabel="' + pointsLabel.escapeHtml4() + '"'
            + ' data-promotedlabel="' + promotedLabel.escapeHtml4() + '"'
            + ' data-demotedlabel="' + demotedLabel.escapeHtml4() + '"'
            + ' data-promotebuttonlabel="' + promoteButtonLabel.escapeHtml4() + '"'
            + ' data-demotebuttonlabel="' + demoteButtonLabel.escapeHtml4() + '"'
            + ' data-categorylabel="' + categoryLabel.escapeHtml4() + '">';

        if(String.isNotBlank(listTitle)) {
            html += '<h2>' + listTitle.escapeHtml4() + '</h2>';
        }

        if(String.isNotBlank(listDescription)) {
            html += '<p>' + listDescription.escapeHtml4() + '</p>';
        }

        html += '<div>'
                + '<form class="filters form-inline">'
                    + '<div class="form-group">'
                        + '<label for="' + categorySelectorId + '" class="sr-only">'
                            + categoryLabel.escapeHtml4()
                        + '</label>'
                        + '<select id="' + categorySelectorId + '" class="category form-control">'
                            + '<option value="">' + categorySelectorLabel.escapeHtml4() + '</option>'
                            // Categories are populated dynamically
                        + '</select>'
                    + '</div>'
                    + ' <div class="form-group">'
                        + '<label for="' + statusSelectorId + '" class="sr-only">'
                            + statusSelectorLabel.escapeHtml4()
                        + '</label>'
                        + '<select id="' + statusSelectorId + '" class="status form-control">'
                            + '<option value="">' + statusSelectorLabel.escapeHtml4() + '</option>'
                            // Statuses are populated dynamically
                        + '</select>'
                    + '</div>'
                    + ' <div class="form-group">'
                        + '<label for="' + searchTextId + '" class="sr-only">'
                            + searchLabel.escapeHtml4()
                        + '</label>'
                        + '<input type="text" id="' + searchTextId + '" class="searchText form-control"'
                            + ' placeholder="' + searchLabel.escapeHtml4() + '">'
                    + '</div>'
                    + ' <button type="submit" class="btn btn-primary">' + refreshLabel.escapeHtml4() + '</button>'
                + '</form>'
            + '</div>';

        html += '<div class="btn-group btn-group-justified">'
                + '<div class="btn-group"><button type="button" class="order btn btn-default" data-order="recent">'
                    + sortRecentLabel.escapeHtml4()
                + '</button></div>'
                + '<div class="btn-group"><button type="button" class="order btn btn-default" data-order="popular">'
                    + sortPopularLabel.escapeHtml4()
                + '</button></div>'
            + '</div>';

        html += '<ul class="ideaSummaries list-group"></ul>';
        html += '<button class="showMore btn btn-default">' + showMoreLabel.escapeHtml4() + '</button>';

        html += '</section>';

        return html;
    }

    public String getIdeaDetailHtml() {
        String idPrefix = this.getContentLayoutInstanceId();

        String html = '';

        html += '<article id="' + idPrefix + '" data-ideadetail>'
            + '<h1 class="title"></h1>'
            + '<div class="media">'
                + '<div class="media-left">'
                    + '<div class="text-center"><span class="points"></span> ' + pointsLabel.escapeHtml4() + '</div>'
                    + '<div class="promoted text-center text-success hidden">' + promotedLabel.escapeHtml4() + '</div>'
                    + '<div class="demoted text-center text-danger hidden">' + demotedLabel.escapeHtml4() + '</div>'
                    + '<button class="vote btn btn-success btn-block hidden" data-votetype="Up">'
                        + promoteButtonLabel.escapeHtml4()
                    + '</button>'
                    + '<button class="vote btn btn-danger btn-block hidden" data-votetype="Down">'
                        + demoteButtonLabel.escapeHtml4()
                    + '</button>'
                + '</div>'
                + '<div class="media-body">'
                    + '<div><span class="createdBy"></span> - <span class="createdDate"></span></div>'
                    + '<div class="category"></div>'
                    + '<div class="status"></div>'
                    + '<div class="body"></div>'
                + '</div>'
            + '</div>' // Idea detail container

            + '<div class="panel panel-default">'
                + '<div class="panel-body">'
                    + '<div class="panel-heading">'
                        + '<h2 class="panel-title">'
                            + commentTitle.escapeHtml4()
                        + '</h2>'
                    + '</div>'
                    + '<div class="panel-body">'
                        + '<button class="addComment btn btn-primary">'
                            + addCommentLabel.escapeHtml4()
                        + '</button>'
                        + '<form class="addCommentForm hidden">'
                            + '<div class="form-group">'
                                + '<textarea class="commentBody form-control" rows="5"></textarea>'
                            + '</div>'
                            + '<button type="submit" class="putComment btn btn-primary">'
                                + addCommentLabel.escapeHtml4()
                            + '</button>'
                            + ' <button type="reset" class="resetComment btn btn-danger">'
                                + resetCommentLabel.escapeHtml4()
                            + '</button>'
                        + '</form>'
                        + '<div class="comments panel-body"></div>'
                    + '</div>'
                + '</div>'
            + '</div>' // Comments container
        + '</article>';

        return html;
    }

    public String getIdeaFormHtml() {
        String idPrefix = this.getContentLayoutInstanceId();
        String titleInputId = idPrefix + '-title';
        String categoryInputId = idPrefix + '-category';
        String bodyInputId = idPrefix + '-body';
        String ideaDetailUrl = '';

        if(this.detailUrl != null) {
            ideaDetailUrl = this.detailUrl.targetPage;
        }

        String html = '';

        html += '<div id="' + idPrefix + '" data-ideaform'
            + ' data-categories="' + categories.escapeHtml4() + '" data-zoneid="' + zoneId + '"'
            + ' data-detailurl="' + ideaDetailUrl.escapeHtml4() + '">';

        if(String.isNotBlank(postIdeaTitle)) {
            html += '<h1>' + postIdeaTitle.escapeHtml4() + '</h1>';
        }

        html += '<form>'
                    + '<div class="form-group">'
                        + '<label for="' + titleInputId + '">' + titleLabel.escapeHtml4() + '</label>'
                        + '<input type="text" class="title form-control"'
                            + 'id="' + titleInputId + '" placeholder="' + titleLabel.escapeHtml4() + '">'
                    + '</div>';

        // If no categories were selected for availability, hide the picklist
        if(categories != '[]') {
            html += '<div class="form-group">'
                        + '<label for="' + categoryInputId + '">' + categoryLabel.escapeHtml4() + '</label>'
                        + '<select id="' + categoryInputId + '" class="category form-control">'
                            + '<option value="">--------</option>'
                            // Categories are populated asynchronously
                        + '</select>'
                    + '</div>';
        }

        html += '<div class="form-group">'
                        + '<label for="' + bodyInputId + '">' + bodyLabel.escapeHtml4() + '</label>'
                        + '<textarea id="' + bodyInputId + '" class="ideaBody form-control" rows="5"></textarea>'
                    + '</div>'
                    + '<button type="submit" class="btn btn-primary">' + submitIdeaLabel.escapeHtml4() + '</button>'
                + '</form>'
            + '</div>';

        return html;
    }

    /**
     * A shorthand to retrieve a default value for a property if it hasn't been saved.
     *
     * @param propertyName the property name, passed directly to getProperty
     * @param defaultValue the default value to use if the retrieved property is null
     */
    @TestVisible
    private String getPropertyWithDefault(String propertyName, String defaultValue) {
        String property = getAttribute(propertyName);

        if(property == null) {
            return defaultValue;
        } else {
            return property;
        }
    }

    public String zoneId {
        get {
            return getPropertyWithDefault('zoneId', '');
        }
    }

    public String categories {
        get {
            return getPropertyWithDefault('categories', '[]');
        }
    }

    /** The number of ideas to show per page. Must be between 1 and 50. Defaults to 20. */
    public Integer pageSize {
        get {
            if(pageSize == null) {
                pageSize = 20; // Default to 20

                try {
                    pageSize = Integer.valueOf(getAttribute('pageSize'));
                } catch(Exception e) {}

                if(pageSize == null) {
                    pageSize = 20;
                } else if(pageSize < 1) {
                    pageSize = 1;
                } else if(pageSize > 50) {
                    pageSize = 50;
                }
            }

            return pageSize;
        } set;
    }

    /** The URL to use when constructing links to an Idea detail page. Used by IdeaList, IdeaForm */
    public cms.Link detailUrl {
        get {
            return getPropertyLink('detailUrl');
        }
    }

    public Boolean isCurrentUser {
        get {
            return getAttribute('isCurrentUser') == 'true';
        }
    }

    /** Title appearing at the top of a List of ideas. Used by IdeaList. */
    public String listTitle {
        get {
            return getPropertyWithDefault('listTitle', 'Ideas');
        }
    }

    /** Plain text appearing directly below the list title. Used by IdeaList. */
    public String listDescription {
        get {
            return getAttribute('listDescription');
        } set;
    }

    /** Title appearing at the top of the Comments related list. Used by IdeaDetail. */
    public String commentTitle {
        get {
            return getPropertyWithDefault('commentTitle', 'Comments');
        }
    }

    /** Title appearing at the top of the Post Idea form. Used by IdeaForm */
    public String postIdeaTitle {
        get {
            return getPropertyWithDefault('postIdeaTitle', 'Post Idea');
        }
    }

    /** Label for the Add Comment button. Used by IdeaDetail. */
    public String addCommentLabel {
        get {
            return getPropertyWithDefault('addCommentLabel', 'Add Comment');
        } set;
    }

    /** Label for the Reset Comment button. Used by IdeaDetail. */
    public String resetCommentLabel {
        get {
            return getPropertyWithDefault('resetCommentLabel', 'Reset Comment');
        } set;
    }

    /** Label for showing idea vote scores, ex. "30 points". Used by IdeaList, IdeaDetail. */
    public String pointsLabel {
        get {
            return getPropertyWithDefault('pointsLabel', 'points');
        } set;
    }

    /** Label for the Promote button. Used by IdeaList and IdeaDetail. */
    public String promotedLabel {
        get {
            return getPropertyWithDefault('promotedLabel', 'Promoted');
        } set;
    }

    /** Label for the Demote button. Used by IdeaList and IdeaDetail. */
    public String demotedLabel {
        get {
            return getPropertyWithDefault('demotedLabel', 'Demoted');
        } set;
    }

    /** Label for the Promote button. Used by IdeaList andIdeaDetail. */
    public String promoteButtonLabel {
        get {
            return getPropertyWithDefault('promoteButtonLabel', 'Promote');
        } set;
    }

    /** Label for the Demote button. Used by IdeaList and IdeaDetail. */
    public String demoteButtonLabel {
        get {
            return getPropertyWithDefault('demoteButtonLabel', 'Demote');
        } set;
    }

    /** Label for the Title field. Used by IdeaForm */
    public String titleLabel {
        get {
            return getPropertyWithDefault('titleLabel', 'Title');
        } set;
    }

    /** Label for the Category field. Used by IdeaList, IdeaForm */
    public String categoryLabel {
        get {
            return getPropertyWithDefault('categoryLabel', 'Category');
        } set;
    }

    /** Default label for the category filter. Used by IdeaList */
    public String categorySelectorLabel {
        get {
            return getPropertyWithDefault('categorySelectorLabel', 'All Categories');
        } set;
    }

    /** Default label for the status filter. Used by IdeaList */
    public String statusSelectorLabel {
        get {
            return getPropertyWithDefault('statusSelectorLabel', 'All Statuses');
        } set;
    }

    /** Label for the Body field. Used by IdeaForm */
    public String bodyLabel {
        get {
            return getPropertyWithDefault('bodyLabel', 'Body');
        } set;
    }

    /** Label for the Search control. Used by IdeaList */
    public String searchLabel {
        get {
            return getPropertyWithDefault('searchLabel', 'Search');
        } set;
    }

    /** Label for the Sort-By-Recent control. Used by IdeaList */
    public String sortRecentLabel {
        get {
            return getPropertyWithDefault('sortRecentLabel', 'Recent');
        } set;
    }

    /** Label for the Sort-By-Popular control. Used by IdeaList */
    public String sortPopularLabel {
        get {
            return getPropertyWithDefault('sortPopularLabel', 'Popular');
        } set;
    }

    /** Label for the IdeaForm submit button. Used by IdeaForm */
    public String submitIdeaLabel {
        get {
            return getPropertyWithDefault('submitIdeaLabel', 'Submit');
        } set;
    }

    /** Label for the refresh button. Used by IdeaList */
    public String refreshLabel {
        get {
            return getPropertyWithDefault('refreshLabel', 'Refresh');
        } set;
    }

    /** Label for the show more button. Used by IdeaList */
    public String showMoreLabel {
        get {
            return getPropertyWithDefault('showMoreLabel', 'Show More');
        } set;
    }

    /** Provides an easy way to define attributes during testing */
    @TestVisible
    private Map<String, String> testAttributes = new Map<String, String>();

    /** Delegates to ContentTemplateController#getProperty in normal execution. Accesses the {@link #testAttributes}
     * map in a test context.
     */
    private String getAttribute(String attributeName) {
        if(Test.isRunningTest()) {
            return testAttributes.get(attributeName);
        } else {
            return getProperty(attributeName);
        }
    }

    private String getContentLayoutInstanceId() {
        if(Test.isRunningTest()) {
            return 'cli_id';
        } else {
            return this.content_layout_instance.Id;
        }
    }

    /** Extension constructor for the Idea edit page */
    global IdeaLayout(cms.CreateContentController cc) {
        super(cc);
    }

    /** Extension constructor for Idea generate pages (unused) */
    private IdeaLayout(cms.GenerateContent gc) {
        super(gc);
    }

    /** Constructor for getHTML rendering */
    global IdeaLayout() {
        super();
    }

    /** Blank getHTML - rendering is done by subclasses */
    global virtual override String getHTML() {
        return '';
    }
}
