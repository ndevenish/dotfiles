# Script from Ben for searching dls people
function ldls() {
 local IFS=';'
 args="$*"
 ldapsearch -LLLxb "ou=People,dc=diamond,dc=ac,dc=uk" \
 -H ldap://ldapmaster.diamond.ac.uk \
 "(|(givenName=${args//;/) (givenName=}) \
  (sn=${args//;/) (sn=}) \
  (cn=${args//;/) (cn=}) \
  (uid=${args//;/) (uid=}))" \
 mail cn uid
}

#Approximate LDAP search tool
function ldlsapprox () {
 local IFS=';'
 args="$*"
 ldapsearch -LLLxb "ou=People,dc=diamond,dc=ac,dc=uk" \
 -H ldap://ldapmaster.diamond.ac.uk \
 "(|(givenName~=${args//;/) (givenName~=}) \
  (sn~=${args//;/) (sn~=}) \
  (cn~=${args//;/) (cn~=}) \
  (uid~=${args//;/) (uid~=}))" \
 mail cn uid
}

