import {Then} from "@badeball/cypress-cucumber-preprocessor";

Then(/^the user opens the warp menu$/, function () {
    cy.get("#warp-menu-shadow-host").shadow().find("#warp-toggle").click({force: true});
});

Then(/^the user checks link corresponding to the static page$/, function () {
    cy.get("#warp-menu-shadow-host").shadow().find(`a[role=menuitem][href="${Cypress.env('staticPagePath')}"]`)
        .should('have.attr', 'target', '_top')
        .contains(`${Cypress.env('nameOfStaticPageLinkInWarpMenu')}`);
});

Then("a static HTML page gets displayed", function () {
    cy.visit(Cypress.config().baseUrl + Cypress.env('staticPagePath'));
    cy.get("h1").should('contain.text', 'About Cloudogu');
});

Then("a static 404 HTML page gets displayed", function () {
    cy.visit({url: Cypress.config().baseUrl + Cypress.env('unknownDoguPath'), failOnStatusCode: false});
    cy.get("title").should('contain.text', '404 Not Found');
});