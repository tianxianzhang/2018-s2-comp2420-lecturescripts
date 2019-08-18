## Exercise - Pharmaceutical Supervision
---
The **CVS Chain of Pharmacies** has offered to give you a free lifetime supply of medicine if you design its database. Given the rising cost of health care, you agree.

* **Patients** are identified by an id, and their names, addresses, and ages must be recorded.

* **Doctors** are identified by an id. For each doctor, the name, speciality, and years of experience must be recorded.

* Each **pharmaceutical company** is identified by name and has a phone number.

* For each **drug**, the trade name and formula must be recorded. Each drug is sold by a given pharmaceutical company,   and the trade name identifies a drug uniquely from among the products of that company. If a pharmaceutical company is deleted, you need not keep track of its products any longer.

* Each **pharmacy** has a name, address, and phone number.

* Every **patient** has a primary physician. Every doctor has at least one patient.

* Each pharmacy sells several drugs and has a price for each. A drug could be sold at several pharmacies, and the price could vary from one pharmacy to another.

* Doctors prescribe drugs for patients. A doctor could prescribe one or more drugs for several patients, and a patient could obtain prescriptions from several doctors. Each prescription has a date and a quantity associated with it. You can assume that, if a doctor prescribes the same drug for the same patient more than once, only the last such prescription needs to be stored.

* Pharmaceutical companies have long-term contracts with pharmacies. A pharmaceutical company can contract with several pharmacies, and a pharmacy can contract with several pharmaceutical companies. For each contract, you have to store a start date, an end date, and the text of the contract.

* Pharmacies appoint a supervisor for each contract. There must always be a supervisor for each contract, but the contract supervisor can change over the lifetime of the contract.

## Modelling Notes - Additional Subtleties
---
The drug entity, as given in the specification above, appears to be weak, and indeed modelling it as such has some benefits (as discussed in the lecture recording), however, when considering the most frequent use cases in our database, it is more likely a drug_id would provide easy of querying. The downside with this approach however, is determining IDs - it would be easy enough to query "All drugs produced by company X", but harder to query "Drug Y from Company X", as you would still need to produce the drug name and company to determine the ID for subsequent queries - this type of pattern however, is a perfect target for an SQL View, or a named sub-query.

As to how this effects the Prescription relationship is going to vary. This relationship needs to be naturally ternary, or else we run into issues reconstructing the prescription. For example, if we encode DocDrug: Many Doctors can prescribe many Drugs, PatientDrug: Many patients can be prescribed multiple drugs, and Visit: Any patient can visit any doctor for a prescription, how are we to determine which of the rows in PatientDrug are the corresponding rows for DocDrug, or Visit? We can't, at least not without assigning new primary keys to each of these relationships, and then relating the relationships. At this point we've created three new, unnatural, entities... and for zero benefit. If we wanted to query a prescription we need to link 5 tables together at a minimum, instead of querying the single Prescribe relationship, that is the natural ternary of Doctors, Patients, and Drugs. This natural ternary works best with a drug_id, providing more justification to turn Drug into a true entity, as opposed to a weak one.

A not so obvious result of this decision is that we have no way to track patients who visit doctors who are not their primary and are NOT prescribed drugs. We can't record this information in the Prescribe relationship as that requires a drug entity. One potential solution is to have a dummy drug (i.e. drug_id 0, which might represent no drug - but then we break our other requirements that a drug must be produced by a company - who produces this one?). If we wanted to record this information, then we would need one more relationship, the aforementioned Visit in the previous paragraph. However, keep in mind that the specification does not mandate that we record these visits, and indeed, keep in mind the client! It's a pharmaceutical company - it seems reasonable they might only care when their drugs happen to be used/prescribed!

With regards to the Supervisors - if we wish to track the history of contract supervisors, then Contract is naturally a ternary relationship between Pharmaceutical Companies, Pharmacies and Supervisors (which are subsequently made an entity since we must track them). In the event we only care to store the current Supervisors details (i.e. a name and a phone number) with no concern with regards to history, then Contract is a simple binary relationship between Pharmaceutical Companies and Pharmacies, with the associated Name/Number as attributes belonging to that relationship.

A note on cardinalities! Most of the binary ones are obvious - the ternary ones here are indicative only in certain special cases, which for the moment we ignore. In general, you can safely treat most 3-ary and greater relationships as many-to-many-to-many-etc... Such constraints can only be encoded logically by using extra functions (such as triggers).