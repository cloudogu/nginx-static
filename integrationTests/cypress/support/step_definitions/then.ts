import {Then} from "@badeball/cypress-cucumber-preprocessor";

Then(/^the user opens the warp menu$/, function () {
    cy.get('*[class^=" warp-menu-column-toggle"]').children('*[id^="warp-menu-warpbtn"]').click();
});

Then(/^the user checks link corresponding to the static page$/, function () {
    cy.get('*[class^=" warp-menu-shift-container"]')
        .children('*[class^=" warp-menu-category-list"]')
        .contains(Cypress.env('nameOfStaticPageLinkInWarpMenu'))
        .should('have.attr', 'target', '_top');
});

Then("a static HTML page gets displayed", function () {
    cy.visit(Cypress.config().baseUrl + Cypress.env('staticPagePath'));
    cy.get("h1").should('contain.text', 'About Cloudogu');
});

Then("a static 404 HTML page gets displayed", function () {
    cy.visit({url: Cypress.config().baseUrl + Cypress.env('unknownDoguPath'), failOnStatusCode: false});
    cy.get("title").should('contain.text', '404 Not Found');
});