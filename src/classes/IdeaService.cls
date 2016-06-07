global with sharing class IdeaService implements cms.ServiceInterface {
    private static Pattern brPattern = Pattern.compile('<br( )?(/)?>');
    private static Pattern tagPattern = Pattern.compile('<.*?>');

    /**
     * Core handler method for retrieving Idea information from Salesforce, voting on an Idea and
     * adding comments to an Idea.
     *
     * @param params a map of parameters including at minimum a value for 'action'
     * @return a JSON-serialized response string
     */
    public String executeRequest(Map<String, String> params) {
        String action = params.get('action');

        try {
            if(action == 'getIdeaList') {
                return getIdeaListJson(params);
            } else if(action == 'getIdeaDetail') {
                return getIdeaDetailJson(params);
            } else if(action == 'putIdea') {
                return putIdeaJson(params);
            } else if(action == 'putIdeaVote') {
                return putIdeaVoteJson(params);
            } else if(action == 'putIdeaComment') {
                return putIdeaCommentJson(params);
            } else if(action == 'getIdeaPicklists') {
                return getIdeaPicklistsJson(params);
            } else if(action == 'getZones') {
                return getZonesJson(params);
            }
        } catch(Exception e) {
            // Unexpected error
            System.debug(e.getStackTraceString());
            String message = e.getMessage();

            return '{"success":false,"message":' + JSON.serialize(message) + '}';
        }

        // No actions matched and no error occurred
        return '{"success":false,"message":"Invalid Action"}';
    }

    public class IdeaServiceException extends Exception {}

    /** Provides common fields for {@link #IdeaSummary} and {@link #IdeaDetail} instances */
    public abstract class IdeaBase {
        public String id;
        public String title;
        public List<String> categories = new List<String>();
        public DateTime createdDate;
        public String status;
        public Decimal votes;
        public String voteStatus;
        public String createdById;
        public String createdByName;

        /** Provides the Idea {@link #createdDate} formatted based on the current user's setting */
        public String createdDateFormatted {
            get {
                return createdDate.format();
            }
        }

        /**
         * Initializes common fields for {@link #IdeaSummary} and {@link #IdeaDetail} instances.
         *
         * <p>Requires the following fields to be defined on the passed Idea object at minimum:
         * <ul>
         * <li>Title</li>
         * <li>Categories</li>
         * <li>CreatedDate</li>
         * <li>Status</li>
         * <li>VoteTotal</li>
         * <li>Votes related list</li>
         * <li>CreatedBy.Name</li>
         * </ul>
         * </p>
         *
         * @param baseObject an Idea instance to derive field values from
         */
        public IdeaBase(Idea baseObject) {
            this.id = baseObject.Id;
            this.title = baseObject.Title;
            if(baseObject.Categories != null) {
                this.categories = baseObject.Categories.split(';');
            }
            this.createdDate = baseObject.CreatedDate;
            this.status = baseObject.Status;
            this.votes = baseObject.VoteTotal;

            this.voteStatus = '';
            if(baseObject.Votes != null) {
                for(Vote v : baseObject.Votes) {
                    if(v.CreatedById == UserInfo.getUserId()) {
                        this.voteStatus = v.Type;
                    }
                }
            }

            this.createdById = baseObject.CreatedBy.Id;
            this.createdByName = baseObject.CreatedBy.Name;
        }
    }

    /** Adds summary-specific fields to the {@link #IdeaBase} abstract class */
    public class IdeaSummary extends IdeaBase {
        /** Holds an opening &lt;a&gt; tag pointing to the author-defined detail page */
        public String detailTag;
        public String summary;

        /** Creates a summary of the idea by truncating the body */
        public IdeaSummary(Idea baseObject) {
            super(baseObject);

            // Create a summary view from the body
            String body = baseObject.Body;
            if(String.isBlank(body)) {
                this.summary = '';
            } else {
                // Convert <br> <br/> <br /> to spaces
                Matcher brMatcher = brPattern.matcher(body);
                body = brMatcher.replaceAll(' ');

                // Strip all other tags
                Matcher tagMatcher = tagPattern.matcher(body);
                body = tagMatcher.replaceAll('');

                if(body.length() > 150)  {
                    body = body.substring(0, 147) + '...';
                }

                this.summary = body;
            }
        }
    }

    /** Adds detail-specific fields to the {@link #IdeaBase} abstract class */
    public class IdeaDetail extends IdeaBase {
        public String body;
        public List<IdeaCommentItem> comments = new List<IdeaCommentItem>();

        /**
         * Initializes the fields for an Idea detail.
         *
         * <p>In addition to the required fields for {@link #IdeaBase}, requires the following fields to be defined
         * on the passed Idea object at minimum:
         * <ul>
         * <li>Body</li>
         * </ul>
         * </p>
         *
         * <p>The relation Comments also may be included and will be processed by
         * {@link #IdeaCommentItem}.</p>
         *
         * @param baseObject an Idea instance to derive field values from
         */
        public IdeaDetail(Idea baseObject) {
            super(baseObject);

            this.body = baseObject.Body;

            if(baseObject.Comments != null) {
                for(IdeaComment comment : baseObject.Comments) {
                    this.comments.add(new IdeaCommentItem(comment));
                }
            }
        }
    }

    /** Provides fields for an Idea Comment attached to an IdeaDetail */
    public class IdeaCommentItem {
        public String createdById;
        public String createdByName;
        public DateTime createdDate;
        public String body;

        /** Provides the IdeaComment {@link #createdDate} formatted based on the current user's setting */
        public String createdDateFormatted {
            get {
                return createdDate.format();
            }
        }

        /**
         * Initializes the fields for a IdeaCommentItem.
         *
         * <p>Requires the following fields to be defined on the passed IdeaComment object at minimum:
         * <ul>
         * <li>CreatedDate</li>
         * <li>CommentBody</li>
         * <li>CreatedBy.Id</li>
         * <li>CreatedBy.Name</li>
         * </ul>
         *
         * @param comment an IdeaComment object to derive field values from
         */
        public IdeaCommentItem(IdeaComment comment) {
            this.createdById = comment.CreatedBy.Id;
            this.createdByName = comment.CreatedBy.Name;
            this.createdDate = comment.CreatedDate;
            this.body = comment.CommentBody;
        }
    }

    /** A parameters object used when fetching a list of ideas. */
    public class IdeaListParameters {
        /** The OrchestraCMS page selector CSV value to use when constructing detail links */
        public String detailUrlCsv;

        /** The zone/community id to retrieve ideas from. */
        public String zoneId;

        /** Return ideas created by the current user. Default false. (optional) */
        public Boolean isCurrentUser;

        /** The category to filter ideas by. Corresponds to Idea#Categories (optional) */
        public String category;

        /** The status to filter ideas by. Corresponds to Idea#Status (optional) */
        public String status;

        /** The search text to filter ideas by. (optional) */
        public String searchText;

        /** The order to return ideas in. May be 'recent' or 'popular'. Defaults to popular. (optional) */
        public String order;

        /** The requested page of cases, with 1 as the first page */
        public Integer pageNumber {
            get; set {
                if(value < 1) {
                    throw new IdeaServiceException('Invalid value for pageNumber');
                }

                pageNumber = value;
            }
        }

        /** The number of ideas to retrieve for each page */
        public Integer pageSize {
            get; set {
                if(value < 1 || value > 50) {
                    throw new IdeaServiceException('Invalid value for pageSize');
                }

                pageSize = value;
            }
        }

        /** Default constructer */
        public IdeaListParameters() {
            this.isCurrentUser = false;
            this.pageNumber = 1;
            this.pageSize = 20;
            this.order = 'popular';
        }
    }

    /** An Idea list result set */
    public class IdeaListResult {
        /** Denotes whether there are more results after the requested page */
        public Boolean hasMore;

        /** The result set of {@link #IdeaSummary} instances */
        public List<IdeaSummary> ideas = new List<IdeaSummary>();
    }

    private String getIdeaListJson(Map<String, String> params) {
        IdeaListParameters listParameters = new IdeaListParameters();

        listParameters.detailUrlCsv = params.get('detailUrlCsv');
        listParameters.zoneId = params.get('zoneId');
        listParameters.isCurrentUser = params.get('isCurrentUser') == 'true';
        listParameters.category = params.get('category');
        listParameters.status = params.get('status');
        listParameters.searchText = params.get('searchText');
        listParameters.order = params.get('order');

        if(String.isNotBlank(params.get('pageNumber'))) {
            try {
                listParameters.pageNumber = Integer.valueOf(params.get('pageNumber'));
            } catch(TypeException e) {
                throw new IdeaServiceException('Invalid value for pageNumber');
            }
        }

        if(String.isNotBlank(params.get('pageSize'))) {
            try {
                listParameters.pageSize = Integer.valueOf(params.get('pageSize'));
            } catch(TypeException e) {
                throw new IdeaServiceException('Invalid value for pageSize');
            }
        }

        IdeaListResult result = getIdeaList(listParameters);
        return '{"success":true,"ideas":' + JSON.serialize(result.ideas) + ',"hasMore":' + result.hasMore + '}';
    }

    /**
     * Fetches a list of ideas.
     *
     * @param params a {@link #IdeaListParameters} instance used to control the result set
     * @return a {@link #IdeaListResult} instance
     */
    public IdeaListResult getIdeaList(IdeaListParameters params) {
        IdeaListResult result = new IdeaListResult();

        String userId = UserInfo.getUserId();

        // Calculate LIMIT/OFFSET values
        Integer queryLimit = params.pageSize;
        Integer queryOffset = (params.pageNumber - 1) * queryLimit;

        String ideaQuerySelect;
        String ideaQueryConditions;
        String ideaQueryOrderLimits;

        // Select
        ideaQuerySelect = 'SELECT Title, Body, toLabel(Categories), CreatedDate,'
            + ' Status, VoteTotal,'
            + ' (SELECT CreatedById, Type FROM Votes WHERE CreatedById = :userId), CreatedBy.Name';

        // From
        ideaQuerySelect += ' FROM Idea';

        // Where
        List<String> whereClauses = new List<String>();
        String zoneId = params.zoneId;
        if(String.isNotBlank(zoneId)) {
            whereClauses.add('CommunityId = :zoneId');
        }

        if(params.isCurrentUser) {
            whereClauses.add('CreatedById = :userId');
        }

        String category = params.category;
        if(String.isNotBlank(params.category)) {
            whereClauses.add('Categories INCLUDES (:category)');
        }

        String status = params.status;
        if(String.isNotBlank(params.status)) {
            whereClauses.add('Status = :status');
        }

        if(String.isNotBlank(params.searchText) && params.searchText != '*') {
            Set<Id> searchResultIds = getSearchResultIds(params.searchText, params.zoneId);
            whereClauses.add('Id IN :searchResultIds');
        }

        if(whereClauses.size() > 0) {
            ideaQueryConditions = ' WHERE ' + String.join(whereClauses, ' AND ');
        } else {
            ideaQueryConditions = '';
        }

        // Order By
        if(params.order == 'recent') {
            ideaQueryOrderLimits = ' ORDER BY CreatedDate DESC';
        } else {
            ideaQueryOrderLimits = ' ORDER BY VoteTotal DESC, CreatedDate DESC';
        }

        // Limit/Offset
        ideaQueryOrderLimits += ' LIMIT :queryLimit OFFSET :queryOffset';

        for(Idea ideaRecord : Database.query(ideaQuerySelect + ideaQueryConditions + ideaQueryOrderLimits)) {
            IdeaSummary summary = new IdeaSummary(ideaRecord);
            summary.detailTag = (new cms.Link(params.detailUrlCsv, null, null, 'ideaId=' + summary.id)).render();

            result.ideas.add(summary);
        }

        // Determine if there are additional pages
        Integer totalIdeas = Database.countQuery('SELECT COUNT() FROM Idea' + ideaQueryConditions);
        Integer ideasUntilEndOfPage = queryOffset + queryLimit;
        result.hasMore = ideasUntilEndOfPage < totalIdeas;

        return result;
    }

    /* Perform a SOSL text search for ideas with the search text either in their fields, or their comments' fields
     *
     * @param text the text to search for
     * @param zoneId the ID of the zone to search within
     */
    private Set<Id> getSearchResultIds(String text, String zoneId) {
        if(!text.endsWith('*')) {
            text += '*';
        }

        List<List<sObject>> result;
        if(zoneId != null && zoneId != '') {
            result = [FIND :text RETURNING Idea(Id WHERE CommunityId = :zoneId),
                    IdeaComment(IdeaId WHERE Idea.CommunityId = :zoneId)];
        } else {
            result = [FIND :text RETURNING Idea(Id),
                    IdeaComment(IdeaId)];
        }

        Set<Id> ids = new Set<Id>();

        // Idea matches
        if(result[0] != null) {
            for(sObject ideaObject : result[0]) {
                ids.add((Id)ideaObject.get('Id'));
            }
        }

        // Comment matches
        if(result[1] != null) {
            for(sObject commentObject : result[1]) {
                ids.add((Id)commentObject.get('IdeaId'));
            }
        }

        return ids;
    }

    private String getIdeaDetailJSON(Map<String, String> params) {
        String ideaId = params.get('ideaId');

        IdeaDetail detail = getIdeaDetail(ideaId);

        return '{"success":true,"idea":'+JSON.serialize(detail)+'}';
    }

    /**
     * Fetches the details of a single idea.
     *
     * @param ideaId the id of the Idea to fetch details for
     * @return a {@link #IdeaDetail} instance, or null if no idea was found for the requested id
     */
    public IdeaDetail getIdeaDetail(String ideaId) {
        String userId = UserInfo.getUserId();

        Idea ideaRecord;
        IdeaDetail result;

        try {
            ideaRecord = [SELECT Title, Body, CreatedDate, toLabel(Status),
                    toLabel(Categories), VoteTotal, CreatedBy.Name,
                    (SELECT CreatedById, Type FROM Votes WHERE CreatedById = :userId),
                    (SELECT CreatedBy.Name, CreatedDate, CommentBody FROM Comments ORDER BY CreatedDate)
                FROM Idea
                WHERE Id = :ideaId];
        } catch(QueryException e) {
            System.debug('Failed to fetch idea ID ' + ideaId);
            System.debug(e);
        }

        if(ideaRecord != null) {
            result = new IdeaDetail(ideaRecord);
        }

        return result;
    }

    private String putIdeaJson(Map<String, String> params) {
        String zoneId = params.get('zoneId');
        String title = params.get('title');

        // Note: Fetching the parameter 'body' from the params map exhibited strange behavior.
        //       We use ideaBody instead and carry that through for consistency.
        String ideaBody = params.get('ideaBody');
        String category = params.get('category');

        Id ideaId = putIdea(zoneId, title, category, ideaBody);

        if(ideaId == null) {
            return '{"success":false}';
        } else {
            return '{"success":true,"ideaId":"' + ideaId + '"}';
        }
    }

    /**
     * Create a new Idea.
     *
     * @param zoneId the id of the zone/community to add the idea to
     * @param title the title of the new idea
     * @param category the category for the new idea
     * @param ideaBody the body of the new idea
     * @return the Id of the newly created comment, or null if the comment could not be created
     */
    public Id putIdea(String zoneId, String title, String category, String ideaBody) {
        Idea newIdea = new Idea(
            CommunityId = zoneId,
            Title = title,
            Categories = category,
            Body = ideaBody
        );

        try {
            insert newIdea;
        } catch(QueryException e) {
            System.debug(e);
            return null;
        }

        return newIdea.Id;
    }

    private String putIdeaVoteJson(Map<String, String> params) {
        String ideaId = params.get('ideaId');
        String vote = params.get('vote');

        return '{"success":' + putIdeaVote(ideaId, vote) + '}';
    }

    /**
     * Vote for an idea.
     *
     * @param ideaId the id of the idea to vote for
     * @param vote the type of vote to add. One of 'Up' or 'Down'
     * @return true on success, false otherwise
     */
    public Boolean putIdeaVote(String ideaId, String vote) {
        if(vote != 'Up' && vote != 'Down') {
            return false;
        }

        Vote newVote;
        try {
            newVote = new Vote(
                ParentId = ideaId,
                Type = vote
            );
        } catch(StringException e) {
            // Invalid ID
            System.debug(e);
            return false;
        }

        try {
            insert newVote;
        } catch(QueryException e) {
            System.debug(e);
            return false;
        }

        return true;
    }

    private String putIdeaCommentJson(Map<String, String> params) {
        String ideaId = params.get('ideaId');
        String comment = params.get('comment');

        return '{"success":' + putIdeaComment(ideaId, comment) + '}';
    }

    /**
     * Adds a comment to an existing idea.
     *
     * @param ideaId the id of the idea to add the comment to
     * @param comment the body of the new comment
     * @return true on success, false on failure
     */
    public Boolean putIdeaComment(String ideaId, String comment) {
        IdeaComment newComment = new IdeaComment(
            IdeaId = ideaId,
            CommentBody = comment
        );

        try {
            insert newComment;
        } catch(QueryException e) {
            System.debug(e);
            return false;
        }

        return true;
    }

    public class IdeaPicklists {
        public List<Schema.PicklistEntry> categories = new List<Schema.PicklistEntry>();
        public List<Schema.PicklistEntry> statuses = new List<Schema.PicklistEntry>();
    }

    private String getIdeaPicklistsJson(Map<String, String> params) {
        IdeaPicklists picklists = getIdeaPicklists();

        JSONGenerator generator = JSON.createGenerator(false);

        generator.writeStartObject();

        generator.writeBooleanField('success', true);
        generator.writeObjectField('categories', picklists.categories);
        generator.writeObjectField('statuses', picklists.statuses);

        return generator.getAsString();
    }

    /** Retrieves the picklist values for the Idea#Categories and Idea#Status picklists. */
    public IdeaPicklists getIdeaPicklists() {
        IdeaPicklists picklists = new IdeaPicklists();

        for(Schema.PicklistEntry entry : Idea.Categories.getDescribe().getPicklistValues()) {
            if(entry.isActive()) {
                picklists.categories.add(entry);
            }
        }

        for(Schema.PicklistEntry entry : Idea.Status.getDescribe().getPicklistValues()) {
            if(entry.isActive()) {
                picklists.statuses.add(entry);
            }
        }

        return picklists;
    }

    private String getZonesJson(Map<String, String> params) {
        Map<Id, String> zones = getZones();

        return '{"success":true,"zones":' + JSON.serialize(zones) + '}';
    }

    /** Retrieves the active zones/communities in the current org */
    public Map<Id, String> getZones() {
        Map<Id, String> zones = new Map<Id, String>();

        for(Community zone : [SELECT Id, Name FROM Community WHERE IsActive = true ORDER BY Name]) {
            zones.put(zone.Id, zone.Name);
        }

        return zones;
    }

    public static Type getType() {
        return IdeaService.class;
    }
}
