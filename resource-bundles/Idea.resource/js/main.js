window.STG = window.STG || {};
window.STG.CTLib = window.STG.CTLib || {};

window.STG.CTLib.Idea = (function(global, namespace, undefined) {
    'use strict';

    var serviceName = 'IdeaService';

    var ideaListContainerSelector = '[data-idealist]';
    var ideaDetailContainerSelector = '[data-ideadetail]';
    var ideaFormContainerSelector = '[data-ideaform]';

    namespace.instances = {};

    /* By default, initialize all idea lists and idea details on document ready */
    $(function() {
        $(ideaListContainerSelector).each(function() {
            namespace.initIdeaList($(this));
        });

        $(ideaDetailContainerSelector).each(function() {
            namespace.initIdeaDetail($(this));
        });

        $(ideaFormContainerSelector).each(function() {
            namespace.initIdeaForm($(this));
        });
    });

    /** Internal utility factory function to produce callback functions for a specific Idea List. */
    function _createGetIdeaListCallback($container, ideaListId) {
        var instance = namespace.instances[ideaListId];

        return function(alwaysTrue, result) {
            // Update instance data
            instance.ideas = instance.ideas.concat(result.ideas);
            instance.hasMore = result.hasMore;

            // Render based on the updated data
            namespace.renderIdeaList($container, instance);
        };
    }

    /** Internal utility function that converts null values to empty strings */
    function _nullToBlank(str) {
        return str === null ? '' : str;
    }

    /**
     * Initializes a new Idea List for a given container element.
     *
     * @param $container a jQuery collection containing the parent element
     */
    namespace.initIdeaList = function($container) {
        var ideaListId = $container.prop('id');
        var pageSize = parseInt($container.attr('data-pagesize'));
        var categoriesJson = $container.attr('data-categories');
        var categories = [];

        var instance;
        var getIdeaListCallback;

        if(isNaN(pageSize) || pageSize < 1 || pageSize > 50) {
            pageSize = 20;
        }

        if(categoriesJson) {
            categories = JSON.parse(categoriesJson);
        }

        instance = namespace.instances[ideaListId] = {
            zoneId: $container.attr('data-zoneid'),
            isCurrentUser: $container.attr('data-iscurrentuser') === 'true',
            status: undefined,
            pageSize: pageSize,
            pageNumber: 1,
            ideas: [],
            hasMore: undefined,
            detailUrlCsv: $container.attr('data-detailurlcsv'),
            category: undefined,
            searchText: undefined,
            order: 'popular',
            pointsLabel: $container.attr('data-pointslabel'),
            promotedLabel: $container.attr('data-promotedlabel'),
            demotedLabel: $container.attr('data-demotedlabel'),
            promoteButtonLabel: $container.attr('data-promotebuttonlabel'),
            demoteButtonLabel: $container.attr('data-demotebuttonlabel'),
            categoryLabel: $container.attr('data-categorylabel')
        };

        namespace.getIdeaPicklists(function(alwaysTrue, data) {
            var $categorySelect = $('.filters .category', $container);
            var $statusSelect = $('.filters .status', $container);
            if(data.success) {
                if(data.categories.length == 0) {
                    $categorySelect.addClass('hidden');
                } else {
                    // For each author-selected category
                    categories.forEach(function(category) {
                        // For each Salesforce picklist entry
                        data.categories.forEach(function(picklistEntry) {
                            // If they match, append the option
                            if(picklistEntry.value == category) {
                                $('<option />')
                                    .prop('value', picklistEntry.value)
                                    .text(picklistEntry.label)
                                    .appendTo($categorySelect);
                            }
                        });
                    });
                }

                if(data.statuses.length == 0) {
                    $statusSelect.addClass('hidden');
                } else {
                    data.statuses.forEach(function(status) {
                        $('<option />')
                            .prop('value', status.value)
                            .text(status.label)
                            .appendTo($statusSelect);
                    });
                }
            } else {
                console.error('Failed to fetch picklists: ' + data.message);
            }
        });

        // Create a callback function for this instance
        getIdeaListCallback = _createGetIdeaListCallback($container, ideaListId);

        namespace.getIdeaList(instance, getIdeaListCallback);

        // Filter submit handler
        $('.filters', $container).submit(function(evt) {
            evt.preventDefault();

            instance.category = $('.category :selected', this).val();
            instance.status = $('.status :selected', this).val();
            instance.searchText = $('.searchText', this).val();
            instance.pageNumber = 1;
            instance.ideas = [];

            namespace.getIdeaList(instance, getIdeaListCallback);
        });

        // Ordering button handler
        $('.order', $container).click(function() {
            var $orderButtons = $('.order', $container);

            instance.pageNumber = 1;
            instance.ideas = [];
            instance.order = $(this).attr('data-order');

            namespace.getIdeaList(instance, getIdeaListCallback);
        });

        // Show more handler
        $('.showMore', $container).click(function() {
            instance.pageNumber ++;
            namespace.getIdeaList(instance, getIdeaListCallback);
        });

        // Summary vote button handler
        $container.on('click', '.vote', function(evt) {
            var $ideaContainer = $(this).parents('.ideaSummary');
            var ideaIndex = $ideaContainer.attr('data-ideaindex');
            var idea = instance.ideas[ideaIndex];
            var voteType = $(this).attr('data-votetype');
            var $voteButtons = $('.vote', $ideaContainer);

            // Disable both vote buttons
            $voteButtons.prop('disabled', true);

            namespace.putIdeaVote(idea.id, voteType, function(alwaysTrue, result) {
                if(result.success) {
                    idea.voteStatus = voteType;
                    idea.votes += 10;

                    namespace.renderIdeaList($container, instance);
                } else {
                    console.error('Vote failed: ' + result.message);
                    $voteButtons.prop('disabled', false);
                }
            });
        });
    };

    /**
     * Initializes a new Idea Detail for a given container element.
     *
     * @param $container a jQuery collection containing the parent element
     */
    namespace.initIdeaDetail = function($container) {
        var ideaId;
        var ideaIdMatch = window.location.search.match(/ideaId=([^&]+)/);

        // Extract the idea ID from the URL
        if(ideaIdMatch != null) {
            ideaId = ideaIdMatch[1];
        }

        if(ideaId === undefined) {
            console.error('Idea ID not specified');
            return;
        }

        // Fetch the idea detail data
        namespace.getIdeaDetail(ideaId, function(alwaysTrue, result) {
            namespace.renderIdeaDetail($container, result.idea);
        });

        // Attach promote/demote click handlers
        $('.vote', $container).click(function(evt) {
            var voteType = $(this).attr('data-votetype');
            var $voteButtons = $('.vote', $container);

            // Disable both vote buttons
            $voteButtons.prop('disabled', true);

            namespace.putIdeaVote(ideaId, voteType, function(alwaysTrue, result) {
                if(result.success) {
                    // Fetch & rerender the idea with the new vote total
                    namespace.getIdeaDetail(ideaId, function(alwaysTrue, result) {
                        namespace.renderIdeaDetail($container, result.idea);
                    });
                } else {
                    console.error('Vote failed: ' + result.message);
                    $voteButtons.prop('disabled', false);
                }
            });
        });

        // Click handler for Add Comment button
        $('.addComment', $container).click(function() {
            $('.addComment', $container).addClass('hidden');
            $('.addCommentForm', $container).removeClass('hidden');
        });

        // Click handler for Reset Comment button
        $('.resetComment', $container).click(function() {
            $('.addComment', $container).removeClass('hidden');
            $('.addCommentForm', $container).addClass('hidden');
        });

        // Submit handler for the Add Comment form
        $('.addCommentForm', $container).submit(function(evt) {
            evt.preventDefault();

            var commentBody = $('.commentBody', this).val();

            namespace.putIdeaComment(ideaId, commentBody, function() {
                namespace.getIdeaDetail(ideaId, function(alwaysTrue, result) {
                    namespace.renderIdeaDetail($container, result.idea);
                });
            });
        });
    };

    /**
     * Renders an idea list.
     *
     * @param $container a jQuery collection containing the parent element
     * @param instance a JavaScript object containg the data for the current state of an idea list
     */
    namespace.renderIdeaList = function($container, instance) {
        var $ideaPanelGroup = $('.ideaSummaries', $container).empty();
        var $panelList = $([]); // Minimize DOM updates by appending all the rows in bulk

        // Set classes on the sort buttons
        $('.order', $container).each(function() {
            var $button = $(this);

            if($button.attr('data-order') == instance.order) {
                $button.removeClass('btn-default').addClass('btn-primary')
            } else {
                $button.removeClass('btn-primary').addClass('btn-default')
            }
        });

        instance.ideas.forEach(function(idea, index) {
            var $panel = $('<li class="ideaSummary list-group-item">').attr('data-ideaindex', index);
            var categoryElements = [];

            if(idea.categories.length > 0) {
                categoryElements = idea.categories.reduce(function(arr, category, index) {
                    if(arr.length > 0) {
                        arr.push(' ');
                    }

                    arr.push($('<span class="label label-default" /> ').text(category));
                    return arr;
                }, [$('<span>').text(instance.categoryLabel + ':')]);
            }

            $('<h2>').append(
                $(idea.detailTag).text(_nullToBlank(idea.title))
            ).appendTo($panel);

            $('<div class="media">').append(
                $('<div class="media-left">').append(
                    $('<div class="text-center">').text(idea.votes + ' ' + instance.pointsLabel),
                    $('<div class="promoted text-center text-success hidden">').text(instance.promotedLabel),
                    $('<div class="demoted text-center text-success hidden">').text(instance.demotedLabel),
                    $('<button class="vote btn btn-success btn-block hidden" data-votetype="Up">')
                        .text(instance.promoteButtonLabel),
                    $('<button class="vote btn btn-danger btn-block hidden" data-votetype="Down">')
                        .text(instance.demoteButtonLabel)
                ),
                $('<div class="media-body">').append(
                    $('<div>').append(
                        $('<span class="createdBy">').text(idea.createdByName),
                        ' - ',
                        $('<span class="createdDate">').text(idea.createdDateFormatted)
                    ),
                    $('<div class="category">').append(categoryElements),
                    $('<div class="status">').text(_nullToBlank(idea.status)),
                    $('<div class="summary">').html(_nullToBlank(idea.summary))
                )
            ).appendTo($panel);

            // Show promoted text, demoted text, or promote/demote buttons
            if(idea.voteStatus == 'Up') {
                $('.promoted', $panel).removeClass('hidden');
            } else if(idea.voteStatus == 'Down') {
                $('.demoted', $panel).removeClass('hidden');
            } else {
                $('.vote', $panel).removeClass('hidden');
            }

            $panelList = $panelList.add($panel);
        });

        $ideaPanelGroup.append($panelList);

        // Show/hide the Show More button
        if(instance.hasMore) {
            $('.showMore', $container).show();
        } else {
            $('.showMore', $container).hide();
        }
    };

    /**
     * Renders an idea detail.
     *
     * @param $container a jQuery collection containing the parent element
     * @param data a JavaScript object containg the data for an Idea
     */
    namespace.renderIdeaDetail = function($container, idea) {
        // Create a set of label spans, one for each category
        var categoryElements = idea.categories.reduce(function(arr, category, index) {
            if(arr.length > 0) {
                arr.push(' ');
            }

            arr.push($('<span class="label label-default" /> ').text(category));
            return arr;
        }, []);
        categoryElements.push('&nbsp;'); // Bootstrap labels require some non-label text or
                                         // their container's margins aren't set properly

        var $commentsList = $('.comments', $container).empty();
        var $commentsItems = $([]);

        // Populate fields
        $('.title', $container).text(_nullToBlank(idea.title));
        $('.createdBy', $container).text(idea.createdByName);
        $('.createdDate', $container).text(idea.createdDateFormatted);
        $('.category', $container).empty().append(categoryElements);
        $('.status', $container).text(_nullToBlank(idea.status));
        $('.body', $container).html(_nullToBlank(idea.body));
        $('.points', $container).text(_nullToBlank(idea.votes));

        // Show promoted text, demoted text, or promote/demote buttons
        if(idea.voteStatus == 'Up') {
            $('.promoted', $container).removeClass('hidden');
        } else if(idea.voteStatus == 'Down') {
            $('.demoted', $container).removeClass('hidden');
        } else {
            $('.vote', $container).removeClass('hidden');
        }

        // Populate comments
        idea.comments.forEach(function(comment) {
            var $commentItem = $('<div class="panel panel-default" />');
            var $heading = $('<div class="panel-heading" />').appendTo($commentItem);
            var $body = $('<div class="panel-body" />').appendTo($commentItem);

            $('<div class="pull-right" />').text(comment.createdDateFormatted).appendTo($heading);
            $('<h4 class="panel-title" />').text(comment.createdByName).appendTo($heading);

            _nullToBlank(comment.body).split('\n').forEach(function(paragraph) {
                paragraph = paragraph.trim();

                if(paragraph === '') {
                    return; // Eliminate "blank" paragraphs
                }

                $('<p />').text(paragraph).appendTo($body);

                $commentsItems = $commentsItems.add($commentItem);
            });
        });

        $commentsList.append($commentsItems);
    };

    /**
     * Initializes a new Idea Form for a given container element.
     *
     * @param $container a jQuery collection containing the parent element
     */
    namespace.initIdeaForm = function($container) {
        var categoriesJson = $container.attr('data-categories');
        var categories = [];
        var $categorySelect = $('.category', $container);
        var zoneId = $container.attr('data-zoneid');
        var detailUrl = $container.attr('data-detailurl');

        if(categoriesJson) {
            categories = JSON.parse(categoriesJson);
        }

        // Detail URL already has query parameters
        if(detailUrl.indexOf('?') != -1) {
            detailUrl += '&ideaId=';
        } else {
            detailUrl += '?ideaId=';
        }

        // Fetch translated picklist labels for the author-secified values
        namespace.getIdeaPicklists(function(alwaysTrue, data) {
            if(!data.success) {
                console.error('Fetching categories failed: ' + data.message);
                return;
            }

            // For each author-selected category
            categories.forEach(function(category) {
                // For each Salesforce picklist entry
                data.categories.forEach(function(picklistEntry) {
                    // If they match, append the option
                    if(picklistEntry.value == category) {
                        $('<option />')
                            .prop('value', picklistEntry.value)
                            .text(picklistEntry.label)
                            .appendTo($categorySelect);
                    }
                });
            });
        });

        // Handle submit click
        $('form', $container).submit(function(evt) {
            evt.preventDefault();

            var title = $('.title', $container).val();
            var category = $('.category :selected', $container).val();
            var ideaBody = $('.ideaBody', $container).val();
            var $submitButton = $('button[type="submit"]', this);

            $submitButton.prop('disabled', true);

            namespace.putIdea(zoneId, title, category, ideaBody, function(alwaysTrue, data) {
                if(data.success) {
                    var ideaUrl = detailUrl + data.ideaId;
                    window.location = ideaUrl;
                } else {
                    $submitButton.prop('disabled', false);
                }
            });
        });
    };

    namespace.getIdeaList = function(params, callback) {
        var requestParams = {
            action: 'getIdeaList',
            detailUrlCsv: params.detailUrlCsv,
            zoneId: params.zoneId,
            isCurrentUser: params.isCurrentUser === true,
            category: params.category,
            status: params.status,
            searchText: params.searchText,
            pageNumber: params.pageNumber,
            pageSize: params.pageSize,
            order: params.order
        };

        $.orchestracmsRestProxy.doAjaxServiceRequest(serviceName, requestParams, callback, null, true); // Read-only mode
    };

    namespace.getIdeaDetail = function(ideaId, callback) {
        var params = {
            action: 'getIdeaDetail',
            ideaId: ideaId
        };

        $.orchestracmsRestProxy.doAjaxServiceRequest(serviceName, params, callback, null, true); // Read-only mode
    };

    namespace.putIdea = function(zoneId, title, category, ideaBody, callback) {
        var params = {
            action: 'putIdea',
            zoneId: zoneId,
            title: title,
            ideaBody: ideaBody,
            category: category
        };

        $.orchestracmsRestProxy.doAjaxServiceRequest(serviceName, params, callback); // Not Read-only mode
    };

    namespace.putIdeaVote = function(ideaId, vote, callback) {
        var params = {
            action: 'putIdeaVote',
            ideaId: ideaId,
            vote: vote
        };

        $.orchestracmsRestProxy.doAjaxServiceRequest(serviceName, params, callback); // Not Read-only mode
    };

    namespace.putIdeaComment = function(ideaId, comment, callback) {
        var params = {
            action: 'putIdeaComment',
            ideaId: ideaId,
            comment: comment
        };

        $.orchestracmsRestProxy.doAjaxServiceRequest(serviceName, params, callback); // Not Read-only mode
    };

    namespace.getIdeaPicklists = function(callback) {
        var params = {
            action: 'getIdeaPicklists'
        };

        $.orchestracmsRestProxy.doAjaxServiceRequest(serviceName, params, callback); // Not Read-only mode
    };
}(window, STG.CTLib.Idea || {}));
