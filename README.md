# Salesforce Ideas

<!-- MarkdownTOC depth=3 -->

1. [Summary](#summary)
    1. [Compatibility](#compatibility)
    1. [Prerequisites](#prerequisites)
    1. [Deployment](#deployment)
    1. [Configuration](#configuration)
1. [Versioning](#versioning)
    1. [Major Versions](#major-versions)
    1. [Minor Versions](#minor-versions)
    1. [Patch Versions](#patch-versions)

<!-- /MarkdownTOC -->

<a name="summary"></a>
## Summary

The Salesforce Ideas content type provides an *Idea List* template that allows a user to view the ideas that they have
access to, an *Idea Detail* template that allows a user to view the details of a single idea, and an *Idea Form* template that allows a user to submit an idea. Users can vote an idea up or down on either the *Idea List* or *Idea Detail* templates, and can see the comments associated with an Idea on the *Idea Detail* template.

<a name="compatibility"></a>
### Compatibility

This content type requires a minimum of OrchestraCMS package 7.184 (Winter 2016, v7.3 Build #7.184).

<a name="prerequisites"></a>
### Prerequisites

1. A compatible version of OrchestraCMS is installed in the target Salesforce organization.
2. A site has been created in OrchestraCMS.

<a name="deployment"></a>
### Deployment

1. Deploy the following Apex classes to the target Salesforce organization
    1. IdeaDetail.cls
    2. IdeaForm.cls
    3. IdeaLayout.cls
    4. IdeaLayout_Test.cls
    5. IdeaList.cls
    6. IdeaService.cls
    7. IdeaService_Test.cls
2. Deploy the following static resources
    1. Idea.resource
3. Deploy the following Visualforce pages to the target Salesforce organization
    1. Idea_Edit.page

<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

<a name="configuration"></a>
### Configuration

Create OrchestraCMS Content Layout records with the following field values:

```
Name : IdeaList
Label : Idea List
Controller : IdeaList
isPageCacheable : true
isContentCacheable : true
Visualforce Edit : c__Idea_Edit
```

```
Name : IdeaDetail
Label : Idea Detail
Controller : IdeaDetail
isPageCacheable : true
isContentCacheable : true
Visualforce Edit : c__Idea_Edit
```

```
Name : IdeaForm
Label : Idea Form
Controller : IdeaForm
isPageCacheable : true
isContentCacheable : true
Visualforce Edit : c__Idea_Edit
```

On the target OrchestraCMS site create the following content type(s) and add content templates as indicated.

```
Name: SalesforceIdeas
Label: Salesforce Ideas
Templates:
    Idea List, autocreate, default
    Idea Form, autocreate
    Idea Detail, autocreate
```

<a name="versioning"></a>
## Versioning

Versions of this content type are numbered MAJOR.MINOR.PATCH.

Any modifications to this code outside of this repository are customizations and will impact upgradeability.

<a name="major-versions"></a>
### Major Versions

Major versions introduce new functionality and may break existing implementations.

<a name="minor-versions"></a>
### Minor Versions

Minor versions introduce new functionality, but will not break existing implementations.

<a name="patch-versions"></a>
### Patch Versions

Patches correct defects in the implementation and do not introduce new functionality.
