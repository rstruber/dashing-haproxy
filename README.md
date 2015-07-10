# dashing-haproxy

## Description

A configurable [Dashing][1] dashboard, widget, and job to display the overall status of your haproxy cluster.

A dynamic widget (HaproxyDownHosts) also displays tiles for each "not up" host in your included backends. A host in maintenance appears in a different color than a host that is down for another reason (like a failed health check).

[1]: https://github.com/Shopify/dashing "Dashing"

## Preview

![Preview - no hosts down](https://github.com/rstruber/dashing-haproxy/blob/master/Preview.png)
![Preview - Host in maintenance](https://github.com/rstruber/dashing-haproxy/blob/master/PreviewMaintenance.png)

## Install

1. Copy widgets/haproxy\_down\_hosts in your widgets folder
2. Copy jobs/haproxy.rb in your jobs folder
3. Copy jobs/dashboards/haproxy.erb in your dashboards folder
4. Copy config.yml.haproxy-example to config.yml to your project root
5. Update config.yml with setting appropriate for your environment
6. Restart dashing

## Configuration

Using the config file you can include and/or exclude individual processes and servers from the haproxy status page.

pxname - Proxy name. The first column in csv status. The name associated to the bind/listen directive.
svname - Server name. The second column in csv status. The label for the backend/server. Can use this to filter "total" rows from results for dashboard.

* instances - Hash of instances where the key is a label used for display and the value is the full url at which the status page for each haproxy instance may be reached
* username - Authenticated user to access status page with
* password - Authenticated user's password
* pxname\_exclude - proxy names to not include in overall status
* pxname\_include - proxy names to specifically include in status
* svname\_exclude - server names to not include in overall status
* svname\_include - server names to specifically include in status
* critical - Percent value as a float (e.g. 50.0) to set percent up tile's background color as red
* warning - Percent value as a float (e.g. 90.0) to set percent up tile's background color as yellow
* red - A hex color code for the percent up tile css-background when percentage is below :critical (default #C44435)
* yellow - A hex color code for the percent up tile css-background when percentage is below :warning (default #E2CF6A)
* green - A hex color code for the percent up tile css-background when percentage is above :warning (default #96bf48)

N.B. Includes/Excludes are evaluated as follows:

1. Pxname and svname are processed independently. Pxname is evaluated first then svname.
2. If includes and excludes are defined - effectively the same as only defining includes - name must be in include and must not be in exclude
3. If only includes are defined - name must be in include list
4. If only excludes are defined - name must not be in exclude list
