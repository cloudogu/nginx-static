import {When} from "@badeball/cypress-cucumber-preprocessor";

When(/^the user opens the always existing cas ui$/, function () {
    cy.visit(Cypress.config().baseUrl + Cypress.env('casPath'));
});

When(/^the user requests the static HTML page$/, function () {
    cy.request(Cypress.env('staticPagePath'));
});

When(/^the user requests the unknown dogu$/, function () {
    cy.request({url: Cypress.env('unknownDoguPath'), failOnStatusCode: false});
});