/* These queries update the element table so that all elements will be
 * associated with a particular burner. The default, 1, represents * Mason.
 * Other burners can take other IDs. Currently, 1 is used for * Mason, and 2 is
 * used for HTML::Template. This feature is new to 1.2.0.
*/

ALTER TABLE element ADD COLUMN burner NUMERIC(2,0) NOT NULL;
ALTER TABLE element ALTER burner SET DEFAULT 1;
UPDATE element SET burner = 1;
