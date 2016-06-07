@isTest
private with sharing class IdeaLayout_Test {
    private static testmethod void testGetPropertyWithDefault() {
        IdeaLayout controller = new IdeaLayout();

        String property = 'propertyName';
        String propertyValue = 'propertyValue';
        String defaultValue = 'default';

        System.assertEquals(defaultValue, controller.getPropertyWithDefault(property, defaultValue),
            'Should return the default value with not attribute value provided');

        controller.testAttributes = new Map<String, String> {
            property => propertyValue
        };

        System.assertEquals(propertyValue, controller.getPropertyWithdefault(property, defaultValue),
            'Should return the stored attribute value when it exists');
    }

    private static testmethod void testGetIdeaListHtml() {
        IdeaLayout baseController = new IdeaLayout();
        IdeaList listController = new IdeaList();

        // Default values are fine
        System.assertEquals(baseController.getIdeaListHtml(), listController.getHtml());
    }

    private static testmethod void testGetIdeaDetailHtml() {
        IdeaLayout baseController = new IdeaLayout();
        IdeaDetail detailController = new IdeaDetail();

        // Default values are fine
        System.assertEquals(baseController.getIdeaDetailHtml(), detailController.getHtml());
    }

    private static testmethod void testGetIdeaFormHtml() {
        IdeaLayout baseController = new IdeaLayout();
        IdeaForm detailController = new IdeaForm();

        // Default values are fine
        System.assertEquals(baseController.getIdeaFormHtml(), detailController.getHtml());
    }

    private static testmethod void testGetHtml() {
        IdeaLayout baseController = new IdeaLayout();

        System.assertEquals('', baseController.getHtml(), 'Default getHtml should return nothing');
    }
}
