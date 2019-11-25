from base64 import b64encode
from hashlib import sha512
import click
import json
import requests
import sys


@click.group()
@click.option('--url', help='HPOS Admin HTTP URL')
@click.pass_context
def cli(ctx, url):
    ctx.obj['url'] = url


def request(ctx, method, path, **kwargs):
    return requests.request(method, ctx.obj['url'] + path, **kwargs)


def get_config_inner(ctx):
    return request(ctx, 'GET', '/v1/config').json()


@cli.command(help='Get hpos-state.json v1.config')
@click.pass_context
def get_config(ctx):
    print(get_config_inner(ctx))


def cas_hash(data):
    dump = json.dumps(data, separators=(',', ':'), sort_keys=True)
    return b64encode(sha512(dump.encode()).digest()).decode()


@cli.command(help='Set hpos-state.json v1.config and trigger NixOS rebuild')
@click.argument('k')
@click.argument('v')
@click.pass_context
def put_config(ctx, k, v):
    config = get_config_inner(ctx)
    cas_hash1 = cas_hash(config)
    config[k] = v

    res = request(ctx, 'PUT', '/v1/config',
                  headers={'x-hpos-admin-cas': cas_hash1},
                  json=config)
    assert res.status_code == requests.codes.ok


@cli.command(help='Get HoloPortOS status data')
@click.pass_context
def get_status(ctx):
    print(request(params, 'GET', '/v1/status').json())


if __name__ == '__main__':
    cli(obj={})
