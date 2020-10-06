---
title: The beginning of OpenID at FEUP
created_at: 2009-06-09
excerpt:
  OpenID at FEUP.
---

Early this year, a friend of mine at
[NIFEUP](https://web.archive.org/web/20090218234900/http://ni.fe.up.pt/) (our
local informatics students' group) developed an application similar to
rapidshare (named
[feupload](https://web.archive.org/web/20110615185519/http://feupload.fe.up.pt/),
although free and limited to our Faculty members. This application used LDAP
server as a means to authenticate the users — you just had to insert your
campus credentials, and an account would be automatically created.

This mechanism, although promoting usability, leads to the usual trust issue:
*you have to give away your credentials to a third party* in order to use the
service.

Now, although we're pretty much honest people regarding these kind of details,
one can imagine the damage that could've been done if we were storing the
users' credentials. Several teachers are using our service. With this in mind,
we had to think of an alternative approach.

Enter [OpenID](https://openid.net/):

> OpenID is a free and easy way to use a single digital identity across the
> Internet.

This is exactly what we were looking for. Basically, the website that requires
authentication redirects the user to his OpenID page, where he can confirm his
identity with his credentials. After being validated, the user is redirected
again to the first website, carrying a token that guarantees his identity. This
way, there's *no need to enter our credentials* in the website requiring
authentication.

OpenID also has some extensions ([Simple
Registration](https://openid.net/specs/openid-simple-registration-extension-1_0.html)
and [Attribute
Exchange](https://openid.net/specs/openid-attribute-exchange-1_0.html)), which
allow the identity provider to automatically fill in registration fields, such
as email address, full name, country, etc. Of course, this requires the user's
permission. Or at least, it should.

So, me and [Pedro Coelho](https://ethereal.io/) proposed implementing this
service so that it can be used with our faculty's credentials. Obviously, it
will be deployed and validated by our IT department so that the users can trust
the service.

Yesterday, we completed the first stage — we achieved OpenID 1.1 full
compliance:

![OpenID@FEUP current status](/articles/openid-compliance1.png)

Now, we need to continue and implement the 2.0 features, along with the SREG/AX
extensions. We'll also need to work on the user interface a bit, so that it
doesn't look like this:

![OpenID@FEUP user interface](/articles/openid-interface.png)

In this case, OpenID can be used not only as a *centralized identity*, but also
as a way for our services to verify if a user belongs to our institution
without asking for their passwords. I'm hoping that we have this finished by
the end of the semester, so that it can be integrated with feupload and other
applications before the next school year.
