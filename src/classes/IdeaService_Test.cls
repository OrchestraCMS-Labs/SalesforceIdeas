@isTest
private with sharing class IdeaService_Test {
    private static IdeaService service = new IdeaService();

    private static Id communityId {
        get {
            if(communityId == null) {
                communityId = [SELECT Id FROM Community LIMIT 1].Id;
            }

            return communityId;
        } set;
    }

    private static User testUser {
        get {
            if(testUser == null) {
                Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
                testUser = new User(
                    Alias = 'test',
                    Email = 'test@test.com',
                    EmailEncodingKey = 'UTF-8',
                    LastName = 'Test',
                    LanguageLocaleKey = 'en_US',
                    LocaleSidKey='en_US',
                    ProfileId = p.Id,
                    TimeZoneSidKey = 'America/New_York',
                    UserName = 'test@test-ocms-ideas.com'
                );
            }

            return testUser;
        } set;
    }

    private static testmethod void testExecuteRequest_getIdeaList() {
        Map<String, String> params = new Map<String, String> {
            'action' => 'getIdeaList'
        };

        String response = service.executeRequest(params);
        System.debug(response);

        System.assert(response.contains('"success":true'), 'Should return a success response with no ideas');
    }

    private static testmethod void testExecuteRequest_getIdeaListInvalidPageNumber() {
        Map<String, String> params = new Map<String, String> {
            'action' => 'getIdeaList',
            'pageNumber' => 'invalid'
        };

        String response = service.executeRequest(params);
        System.debug(response);

        System.assert(response.contains('"success":false'), 'Should return an unsuccessful response');
    }

    private static testmethod void testExecuteRequest_getIdeaListInvalidPageSize() {
        Map<String, String> params = new Map<String, String> {
            'action' => 'getIdeaList',
            'pageSize' => 'invalid'
        };

        String response = service.executeRequest(params);
        System.debug(response);

        System.assert(response.contains('"success":false'), 'Should return an unsuccessful response');
    }

    private static testmethod void testExecuteRequest_getIdeaDetail() {
        Idea testIdea = new Idea(
            CommunityId = communityId,
            Title = 'title'
        );

        insert testIdea;

        Map<String, String> params = new Map<String, String> {
            'action' => 'getIdeaDetail',
            'ideaId' => testIdea.Id
        };

        String response = service.executeRequest(params);
        System.debug(response);

        System.assert(response.contains('"success":true'), 'Should return a success response');
    }

    private static testmethod void testExecuteRequest_putIdea() {
        Map<String, String> params = new Map<String, String> {
            'action' => 'putIdea',
            'zoneId' => communityId,
            'title' => 'title',
            'ideaBody' => 'body'
        };

        String response = service.executeRequest(params);
        System.debug(response);

        System.assert(response.contains('"success":true'), 'Should return a success response');
    }

    private static testmethod void testExecuteRequest_putIdeaVote() {
        Idea testIdea = new Idea(
            CommunityId = communityId,
            Title = 'title'
        );

        insert testIdea;

        Map<String, String> params = new Map<String, String> {
            'action' => 'putIdeaVote',
            'ideaId' => testIdea.Id,
            'vote' => 'Up'
        };

        String response;
        System.runAs(testUser) {
            response = service.executeRequest(params);
        }

        System.debug(response);

        System.assert(response.contains('"success":true'), 'Should return a success response');
    }

    private static testmethod void testExecuteRequest_putIdeaComment() {
        Idea testIdea = new Idea(
            CommunityId = communityId,
            Title = 'title'
        );

        insert testIdea;

        Map<String, String> params = new Map<String, String> {
            'action' => 'putIdeaComment',
            'ideaId' => testIdea.Id,
            'comment' => 'test comment'
        };

        String response = service.executeRequest(params);
        System.debug(response);

        System.assert(response.contains('"success":true'), 'Should return a success response');
    }

    private static testmethod void testExecuteRequest_getIdeaPicklists() {
        Map<String, String> params = new Map<String, String> {
            'action' => 'getIdeaPicklists'
        };

        String response = service.executeRequest(params);
        System.debug(response);

        System.assert(response.contains('"success":true'), 'Should return a success response');
    }

    private static testmethod void testExecuteRequest_getZones() {
        Map<String, String> params = new Map<String, String> {
            'action' => 'getZones'
        };

        String response = service.executeRequest(params);
        System.debug(response);

        System.assert(response.contains('"success":true'), 'Should return a success response');
    }

    private static testmethod void testExecuteRequest_invalidAction() {
        Map<String, String> params = new Map<String, String> {
            'action' => 'invalid action'
        };

        String response = service.executeRequest(params);
        System.debug(response);

        System.assert(response.contains('"success":false'), 'Should return a failure response');
    }

    private static testmethod void testGetIdeaList() {
        IdeaService.IdeaListParameters params = new IdeaService.IdeaListParameters();
        IdeaService.IdeaListResult result;

        Integer testIdeaCount = 100;

        List<Idea> testIdeas = new List<Idea>();
        List<Idea> testIdeasCategory0 = new List<Idea>();

        for(Integer i = 0; i < testIdeaCount; ++i) {
            Idea newIdea = new Idea(
                Title = 'idea title ' + i,
                Body = 'idea body ' + i,
                CommunityId = communityId,
                Categories = 'ideaCategory' + Math.mod(i, 10),
                Status = 'New'
            );

            testIdeas.add(newIdea);
            if(Math.mod(i, 10) == 0) {
                testIdeasCategory0.add(newIdea);
            }
        }

        Idea lastIdea = testIdeas[testIdeaCount - 1];
        Idea lastIdeaCategory0 = testIdeasCategory0[(testIdeaCount / 10) - 1];

        insert testIdeas;

        Test.startTest();

        // No filters
        result = service.getIdeaList(params);

        System.assertEquals(params.pageSize, result.ideas.size(), 'Should return one page of test ideas');
        System.assertEquals(lastIdea.Title, result.ideas[0].title, 'Should return the last-inserted idea first');
        System.assert(result.hasMore, 'Should indicate more results');

        // Exact filter
        params = new IdeaService.IdeaListParameters();
        params.zoneId = communityId;
        params.category = testIdeas[0].Categories; // Should match 10 of the 100 test ideas
        params.status = testIdeas[0].Status;
        params.isCurrentUser = true;
        params.order = 'recent';

        result = service.getIdeaList(params);

        System.assertEquals(10, result.ideas.size(), 'Should return 10 test ideas');
        System.assertEquals(LastIdeaCategory0.Title, result.ideas[0].title, 'Should return the last category0 idea');
        System.assert(!result.hasMore, 'Should not indicate more results');

        // Non-matching filter
        params = new IdeaService.IdeaListParameters();
        params.category = 'other category';
        params.status = 'invalid status';

        result = service.getIdeaList(params);

        System.assertEquals(0, result.ideas.size(), 'Should return no results');
        System.assert(!result.hasMore, 'Should not indicate more results');

        Test.stopTest();
    }

    private static testmethod void testGetIdeaDetail_validId() {
        Idea testIdea = new Idea(
            CommunityId = communityId,
            Title = 'test title',
            Body = 'test body'
        );

        insert testIdea;

        IdeaComment testComment = new IdeaComment(
            IdeaId = testIdea.Id,
            CommentBody = 'test comment'
        );

        insert testComment;

        IdeaService.IdeaDetail retrievedIdea = service.getIdeaDetail(testIdea.Id);

        System.assertEquals(testIdea.Id, retrievedIdea.id, 'Retrieved idea should have the requested id');
        System.assertEquals(testIdea.Title, retrievedIdea.title, 'Retrieved idea should have the correct title');
        System.assertEquals(testIdea.Body, retrievedIdea.body, 'Retrieved idea should have the correct body');

        System.assertEquals(10, retrievedIdea.votes, 'Retrieved idea should have the default 10 votes');
        System.assertEquals('Up', retrievedIdea.voteStatus,
            'Retrieved idea should have the default vote status of \'Up\'');

        System.assertEquals(1, retrievedIdea.comments.size(), 'Retrieved idea should have 1 comment');
        System.assertEquals(testComment.CommentBody, retrievedIdea.comments[0].body,
            'Retrieved idea comment should have the correct body');
    }

    private static testmethod void testGetIdeaDetail_invalidId() {
        IdeaService.IdeaDetail retrievedIdea = service.getIdeaDetail('invalid id');

        System.assertEquals(null, retrievedIdea, 'Should return null for an invalid id');
    }

    private static testmethod void testPutIdea() {
        String title = 'test title';
        String category = 'test category';
        String body = 'test body';

        String ideaId = service.putIdea(communityId, title, category, body);

        Idea insertedIdea = [SELECT CommunityId, Title, Categories, Body FROM Idea WHERE Id = :ideaId];

        System.assertEquals(communityId, insertedIdea.CommunityId, 'Should insert the provided community/zone id');
        System.assertEquals(title, insertedIdea.Title, 'Should insert the provided title');
        System.assertEquals(category, insertedIdea.Categories, 'Should insert the provided category');
        System.assertEquals(body, insertedIdea.Body, 'Should insert the provided body');
    }

    private static testmethod void testPutIdeaVote_success() {
        String voteType = 'Up';

        Idea testIdea = new Idea(
            CommunityId = communityId,
            Title = 'test title',
            Body = 'test body'
        );

        insert testIdea;

        Boolean putVoteSucceeded;
        System.runAs(testUser) {
            putVoteSucceeded = service.putIdeaVote(testIdea.Id, voteType);
        }

        Vote retrievedVote = [SELECT Type FROM Vote
            WHERE ParentId = :testIdea.Id AND CreatedById = :testUser.Id];

        System.assert(putVoteSucceeded, 'Should succeed in adding the vote');

        System.assertEquals(voteType, retrievedVote.Type, 'Should put the correct type of vote');
    }

    private static testmethod void testPutIdeaVote_invalidVoteType() {
        String voteType = 'invalid vote type';

        Idea testIdea = new Idea(
            CommunityId = communityId,
            Title = 'test title',
            Body = 'test body'
        );

        insert testIdea;

        Boolean putVoteSucceeded;
        System.runAs(testUser) {
            putVoteSucceeded = service.putIdeaVote(testIdea.Id, voteType);
        }

        System.assert(!putVoteSucceeded, 'Should fail with an invalid vote type');
    }

    private static testmethod void testPutIdeaVote_invalidIdeaId() {
        Boolean putVoteSucceeded = service.putIdeaVote('invalid id', 'Up');

        System.assert(!putVoteSucceeded, 'Should fail with an invalid idea id');
    }

    private static testmethod void testPutIdeaComment_success() {
        String comment = 'test comment';

        Idea testIdea = new Idea(
            CommunityId = communityId,
            Title = 'test title',
            Body = 'test body'
        );

        insert testIdea;

        Boolean putCommentSucceeded = service.putIdeaComment(testIdea.Id, comment);

        IdeaComment retrievedComment = [SELECT CommentBody FROM IdeaComment WHERE IdeaId = :testIdea.Id];

        System.assert(putCommentSucceeded, 'Should succeed in adding the comment');

        System.assertEquals(comment, retrievedComment.CommentBody, 'Should put the correct comment body');
    }

    private static testmethod void testGetIdeaPicklists() {
        IdeaService.IdeaPicklists picklists = service.getIdeaPicklists();

        System.assertNotEquals(null, picklists.categories, 'Should return a list of categories');
        System.assertNotEquals(null, picklists.statuses, 'Should return a list of statuses');
    }

    private static testmethod void testGetZones() {
        Map<Id, String> zones = service.getZones();

        System.assertNotEquals(null, zones, 'Should return a valid map');
    }

    private static testmethod void testGetType() {
        Type ideaServiceType = IdeaService.getType();

        System.assertEquals(IdeaService.class, ideaServiceType, 'Should return IdeaService.class');
    }
}
